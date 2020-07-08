# frozen_string_literal: true

require 'railway_ipc/consumer/consumer_response_handlers'

module RailwayIpc
  class Consumer
    include Sneakers::Worker

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

    def queue_name
      queue.name
    end

    def exchange_name
      queue.opts[:exchange]
    end

    def work(payload)
      message = RailwayIpc::IncomingMessage.new(payload)
      RailwayIpc::ProcessIncomingMessage.call(self, message)
      ack!
    rescue StandardError => e
      RailwayIpc.logger.log_exception(
        feature: 'railway_consumer',
        error: e.class,
        error_message: e.message,
        payload: payload
      )
      raise e
    end

    def get_handler(type)
      manifest = ConsumerResponseHandlers.instance.get(type)
      manifest ? manifest.handler.new : nil
    end
  end
end
