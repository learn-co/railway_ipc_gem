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
        process_unknown_message_type(decoded_payload: decoded_payload, protobuff_message: protobuff_message)
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
      existing_record = RailwayIpc::ConsumedMessage.find_by(uuid: protobuff_message.uuid)

      if existing_record && existing_record.processed?
        handler.ack!
        return
      end

      if existing_record
        existing_record.with_lock("FOR UPDATE NOWAIT") do
          response = handler.handle(protobuff_message)

          if response.success?
            existing_record.status = RailwayIpc::ConsumedMessage::STATUSES[:success]
          else
            existing_record.status = RailwayIpc::ConsumedMessage::STATUSES[:failed_to_process]
          end

          existing_record.save!
        end

        return
      end

      new_record = RailwayIpc::ConsumedMessage.create!(
        uuid: protobuff_message.uuid,
        status: RailwayIpc::ConsumedMessage::STATUSES[:processing],
        message_type: decoded_payload.type,
        user_uuid: protobuff_message.user_uuid,
        correlation_id: protobuff_message.correlation_id,
        queue: delivery_info.consumer.queue.name,
        exchange: delivery_info.exchange,
        encoded_message: decoded_payload.message
      )

      new_record.with_lock("FOR UPDATE NOWAIT") do
        response = handler.handle(protobuff_message)

        if response.success?
          new_record.status = RailwayIpc::ConsumedMessage::STATUSES[:success]
        else
          new_record.status = RailwayIpc::ConsumedMessage::STATUSES[:failed_to_process]
        end

        new_record.save!
      end

      return
    end

    def process_unknown_message_type(decoded_payload:, protobuff_message:)
      existing_record = RailwayIpc::ConsumedMessage.find_by(uuid: protobuff_message.uuid)

      if existing_record
        RailwayIpc::NullHandler.new.ack!
      end
    end

    def message_handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).message
    end

    def handler_for(decoded_payload)
      ConsumerResponseHandlers.instance.get(decoded_payload.type).handler.new
    end
  end
end
