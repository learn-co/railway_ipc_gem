# frozen_string_literal: true

module RailwayIpc
  module Rabbitmq
    class Adapter
      class TimeoutError < StandardError
      end
      extend Forwardable
      attr_reader :connection, :exchange, :exchange_name, :queue, :queue_name, :channel
      def_delegators :connection,
                     :automatically_recover?,
                     :connected?,
                     :host,
                     :logger,
                     :pass,
                     :port,
                     :user

      def initialize(amqp_url: ENV['RAILWAY_RABBITMQ_CONNECTION_URL'], exchange_name:, queue_name: '', options: {})
        @queue_name = queue_name
        @exchange_name = exchange_name
        settings = AMQ::Settings.parse_amqp_url(amqp_url)
        vhost = settings[:vhost] || '/'
        @connection = Bunny.new({
          host: settings[:host],
          user: settings[:user],
          pass: settings[:pass],
          port: settings[:port],
          vhost: vhost,
          automatic_recovery: false,
          logger: RailwayIpc.bunny_logger
        }.merge(options))
      end

      def publish(message, options={})
        exchange&.publish(message, options)
      end

      def reply(message, from)
        channel.default_exchange.publish(message, routing_key: from)
      end

      def subscribe(&block)
        queue.subscribe(&block)
      end

      def check_for_message(timeout: 10, time_elapsed: 0, &block)
        raise TimeoutError if time_elapsed >= timeout

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

      def disconnect
        channel.close
        connection.close
        self
      end

      def create_exchange(strategy: :fanout, options: { durable: true })
        @exchange = Bunny::Exchange.new(connection.channel, :fanout, exchange_name, options)
        self
      end

      def delete_exchange
        exchange&.delete
        self
      end

      def create_queue(options={ durable: true })
        @queue = @channel.queue(queue_name, options)
        self
      end

      def bind_queue_to_exchange
        queue.bind(exchange)
        self
      end

      def delete_queue
        queue&.delete
        self
      end
    end
  end
end
