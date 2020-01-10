require "json"
require "base64"
require "railway_ipc/consumer/consumer_response_handlers"

module RailwayIpc
  class Consumer
    include Sneakers::Worker
    attr_reader :message, :handler

    def self.listen_to(queue:, exchange:)
      from_queue queue,
                 exchange: exchange,
                 durable: true,
                 exchange_type: :fanout,
                 connection: RailwayIpc.bunny_connection
    end

    def self.handle(message_type, with:)
      ConsumerResponseHandlers.instance.register(message: message_type, handler: with)
    end

    def registered_handlers
      ConsumerResponseHandlers.instance.registered
    end

    def work_with_params(payload, delivery_info, _metadata)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)

      case decoded_payload.type
      when *registered_handlers
        @handler = handler_for(decoded_payload)
        message_klass = message_handler_for(decoded_payload)
        protobuff_message = message_klass.decode(decoded_payload.message)
        process(decoded_payload: decoded_payload, protobuff_message: protobuff_message, delivery_info: delivery_info)
      else
        protobuff_message = RailwayIpc::BaseMessage.decode(decoded_payload.message)
         # TODO call process w/wo handler arg
         # auto use type: RailwayIpc::NullMessage in method definition
         # ConsumedMessage.persist_unknown_message_type(encoded_message: decoded_payload.message, decoded_message: decoded_message)
        RailwayIpc::NullHandler.new.handle(protobuff_message)
      end

      rescue StandardError => e
        RailwayIpc.logger.log_exception(
          feature: "railway_consumer",
          error: e.class,
          error_message: e.message,
          payload: payload,
        )
        raise e
    end

    private

    def process(decoded_payload:, protobuff_message:, delivery_info:)
      consumed_message = RailwayIpc::ConsumedMessage.find_by(uuid: protobuff_message.uuid)

      if consumed_message && consumed_message.processed?
        handler.ack!
        return
      end

      handler.handle(protobuff_message)
    end

    def message_handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).message
    end

    def handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).handler.new
    end
  end
end
