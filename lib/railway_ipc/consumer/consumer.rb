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
      # decode payload (this is worthless without a decoded payload)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      binding.pry
      # find of create a consumed message record
      # lock the database row
      # call the handler
      # record the status response from the handled message
      # unlock the database row
      # How soon can we find or create by? It would be great to have the message UUI, but I don't think we have that until we have decocded the msg into a protobuff??
      # We could find or create by the encoded message but that doesn't feel like a good idea at scale... Maybe decode each message into the base one first?


      case decoded_payload.type
      when *registered_handlers
        @handler = handler_for(decoded_payload)
        message_klass = message_handler_for(decoded_payload)
        protobuff_message = message_klass.decode(decoded_payload.message)

        # ConsumedMessage.persist_with_lock!() { handler.handle(message) }
        process(encoded_message: decoded_payload.message, protobuff_message: protobuff_message, type: message_klass, handler: handler, delivery_info: delivery_info)
      else
        message = RailwayIpc::BaseMessage.decode(decoded_payload.message)
        ConsumedMessage.persist_unknown_message_type(encoded_message: decoded_payload.message, decoded_message: decoded_message) # auto use type: RailwayIpc::NullMessage in method definition
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

    defp process(encoded_message: encoded_message, protobuff_message: protobuff_message, type: message_klass, handler: handler) do
      # find or create
      consumed_message = ConsumedMessage.find_or_create_by(uuid: protobuff_message.uuid)
      # lock
      return if consumed_message.succeeded # need to write that function
      consumed_message.with_lock("FOR UPDATE NOWAIT") do
        message.update(
          message_type: message_klass,
          user_uuid: protobuff_message.user_uuid,
          correlation_id: protobuff_message.correlation_id,
          encoded_message: encoded_message,
          status: 'pending',
          queue: delivery_info.queue,
          exchange: delivery_info.exchange
        )
        # handle
        results = handler.handle_message(protobuff_message)
        # update status
        message.update(status: results.status)

      end
      # ConsumedMessage.persist_with_lock!(encoded_message: decoded_payload.message, protobuff_message: protobuff_message, type: message_klass) { handler.handle(message) }
    end

    private

    def message_handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).message
    end

    def handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).handler.new
    end
  end
end
