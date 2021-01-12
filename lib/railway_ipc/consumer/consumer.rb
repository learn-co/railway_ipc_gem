# frozen_string_literal: true

module RailwayIpc
  class Consumer
    include Sneakers::Worker

    def self.inherited(base)
      super

      base.instance_eval do
        def handlers
          @handlers ||= RailwayIpc::HandlerStore.new
        end
      end
    end

    # rubocop:disable Metrics/MethodLength
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
        arguments: {
          'x-dead-letter-exchange' => 'ipc:errors'
        },
        connection: RailwayIpc.bunny_connection
      }.merge(options)
    end
    # rubocop:enable Metrics/MethodLength

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

    # REFACTOR: Long term we should think about not leaking Sneakers
    # methods as part of Railway's public API since clients can (and do)
    # override them. -BN
    def work_with_params(payload, _delivery_info, metadata)
      headers = metadata.headers || {}
      message_format = headers.fetch('message_format', 'protobuf_binary')

      message = RailwayIpc::IncomingMessage.new(payload, message_format: message_format)
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
      reject!
    end

    def get_handler(type)
      manifest = handlers.get(type)
      manifest ? manifest.handler.new : nil
    end
  end
end
