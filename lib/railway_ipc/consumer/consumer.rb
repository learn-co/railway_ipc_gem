require 'json'
require 'base64'

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

    def work(payload)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      case decoded_payload.type
      when *ConsumerResponseHandlers.instance.registered
        @handler = ConsumerResponseHandlers.instance.get(decoded_payload.type).handler.new
        message_klass = ConsumerResponseHandlers.instance.get(decoded_payload.type).message
      else
        @handler = RailwayIpc::NullHandler.new
        message_klass = RailwayIpc::NullMessage
      end
      message = message_klass.decode(decoded_payload.message)
      handler.handle(message)
    rescue StandardError => e
      RailwayIpc.logger.log_exception(
          feature: 'railway_consumer',
          error: e.class,
          error_message: e.message,
          payload: payload
      )
      raise e
    end
  end
end
