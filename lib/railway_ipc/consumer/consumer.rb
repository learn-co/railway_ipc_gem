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

    def work(payload)
      # find of create a consumed message record
      # lock the database row
      # call the handler
      # record the status response from the handled message
      # unlock the database row
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)

      case decoded_payload.type
      when *registered_handlers
        @handler = handler_for(decoded_payload)
        message_klass = message_handler_for(decoded_payload)
      else
        @handler = RailwayIpc::NullHandler.new
        message_klass = RailwayIpc::NullMessage
      end
      message = message_klass.decode(decoded_payload.message)

      ConsumedMessage.persist(decoded_payload) do
        handler.handle(message)
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
