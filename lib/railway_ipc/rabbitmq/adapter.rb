module RailwayIpc
  module Rabbitmq
    class Adapter
      extend Forwardable
      attr_reader :connection, :exchange, :exchange_name, :queue, :queue_name
      def_delegators :connection,
                     :automatically_recover?,
                     :connected?,
                     :host,
                     :logger,
                     :pass,
                     :port,
                     :user

      def initialize(connection_options:)
        amqp_url = connection_options.amqp_url
        @queue_name = connection_options.queue
        @exchange_name = connection_options.exchange
        settings = AMQ::Settings.parse_amqp_url(amqp_url)
        @connection = Bunny.new(
            host: settings[:host],
            user: settings[:user],
            pass: settings[:pass],
            port: settings[:port],
            automatic_recovery: false,
            logger: RailwayIpc.bunny_logger
        )
      end

      def publish(message, options={})
        exchange.publish(message, options) if exchange
      end

      def check_for_message(timeout: 10, time_elapsed: 0, &block)
        raise "timeout" if time_elapsed >= timeout

        block ||= ->(result) { result }

        result = queue.pop
        return block.call(*result) if result.compact.any?

        sleep 1
        check_for_message(timeout: timeout, time_elapsed: time_elapsed + 1, &block)
      end

      def connect
        connection.start
        @channel = connection.channel
        self
      end

      def create_exchange(strategy: :fanout, options: {durable: true})
        @exchange = Bunny::Exchange.new(connection.channel, :fanout, exchange_name, options)
        self
      end

      def delete_exchange
        exchange.delete if exchange
        self
      end

      def create_queue
        @queue = @channel.queue(queue_name, durable: true).bind(exchange)
        self
      end

      def delete_queue
        queue.delete if queue
        self
      end
    end
  end
end
