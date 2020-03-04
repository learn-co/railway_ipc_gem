require "json"
require "base64"
require "railway_ipc/consumer/consumer_response_handlers"

module RailwayIpc
  class Consumer
    include Sneakers::Worker
    attr_reader :message, :handler, :protobuf_message, :delivery_info, :decoded_payload, :encoded_message

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
      @delivery_info = delivery_info
      @decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      @encoded_message = payload

      case decoded_payload.type
      when *registered_handlers
        @handler = handler_for(decoded_payload)
        message_klass = message_handler_for(decoded_payload)
        @protobuf_message = message_klass.decode(decoded_payload.message)
        process_known_message_type
      else
        @handler = RailwayIpc::NullHandler.new
        @protobuf_message = RailwayIpc::BaseMessage.decode(decoded_payload.message)
        process_unknown_message_type
      end
      @handler.ack!
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

    def process_protobuf!(message)
      response = handler.handle(protobuf_message)
      message.status = RailwayIpc::ConsumedMessage.response_to_status(response)

      message.save!
    end

    def process_known_message_type
      message = RailwayIpc::ConsumedMessage.find_by(uuid: protobuf_message.uuid)

      return if message && message.processed?

      if message && !message.processed?
        message.with_lock("FOR UPDATE NOWAIT") { process_protobuf!(message) }
      else
        message = create_message_with_status!(RailwayIpc::ConsumedMessage::STATUSES[:processing])
        message.with_lock("FOR UPDATE NOWAIT") { process_protobuf!(message) }
      end
    end

    def process_unknown_message_type
      if RailwayIpc::ConsumedMessage.exists?(uuid: protobuf_message.uuid)
        return
      else
        create_message_with_status!(RailwayIpc::ConsumedMessage::STATUSES[:unknown_message_type])
      end
    end

    def create_message_with_status!(status)
      RailwayIpc::ConsumedMessage.create!(
        uuid: protobuf_message.uuid,
        status: status,
        message_type: decoded_payload.type,
        user_uuid: protobuf_message.user_uuid,
        correlation_id: protobuf_message.correlation_id,
        queue: delivery_info.consumer.queue.name,
        exchange: delivery_info.exchange,
        encoded_message: encoded_message
      )
    end

    def message_handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).message
    end

    def handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).handler.new
    end
  end
end
