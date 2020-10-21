# frozen_string_literal: true

module RailwayIpc
  class Consumer
    include Sneakers::Worker

    def self.inherited(base)
      base.instance_eval do
        def handlers
          @handlers ||= RailwayIpc::HandlerStore.new
        end
      end
    end

    def self.listen_to(queue:, exchange:, options: {})
      unless options.empty?
        RailwayIpc.logger.info(
          "Overriding configuration for #{queue} with new options",
          feature: 'railway_ipc_consumer',
          options: options
        )
      end

      from_queue queue, {
        exchange: exchange,
        durable: true,
        exchange_type: :fanout,
        connection: RailwayIpc.bunny_connection
      }.merge(options)
    end

    def self.handle(message_type, with:)
      handlers.register(message: message_type, handler: with)
    end

    def handlers
      self.class.handlers
    end

    def registered_handlers
      handlers.registered
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
      RailwayIpc.logger.error(
        e.message,
        feature: 'railway_ipc_consumer',
        exchange: exchange_name,
        queue: queue_name,
        error: e.class,
        payload: payload
      )
      raise e
    end

    def get_handler(type)
      manifest = handlers.get(type)
      manifest ? manifest.handler.new : nil
    end
  end
end
