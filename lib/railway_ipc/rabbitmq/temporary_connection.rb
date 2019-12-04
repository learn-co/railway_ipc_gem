require 'bunny'
module RailwayIpc
  module Rabbitmq
    class RabbitConnectionOptions
      attr_reader :amqp_url, :exchange, :queue, :options
      def initialize(amqp_url: ENV["RAILWAY_RABBITMQ_CONNECTION_URL"], exchange:, queue:, options: {})
        @amqp_url = amqp_url
        @exchange = exchange
        @queue = queue
        @options = options
      end
    end

    class TemporaryConnection
      attr_reader :rabbit_connection
      def create_rabbit_connection(connection_options)
        RailwayIpc::Rabbitmq::Adapter.new(connection_options)
      end

      def default_connection_options
        RabbitConnectionOptions.new(amqp_url: ENV["RAILWAY_RABBITMQ_CONNECTION_URL"], rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
      end

      def initialize(connection_options: default_connection_options)
        @rabbit_connection = create_rabbit_connection(connection_options)
        @rabbit_connection_options = connection_options
      end

      def start
        rabbit_connection.start
        @channel = rabbit_connection.create_channel
        @exchange = Bunny::Exchange.new(channel, :fanout, @rabbit_connection_options.options[:exchange_name], durable: true)
        @channel.queue(self.class.queue_name, durable: true).bind(exchange)
      end


      def stop
        channel.close
        rabbit_connection.close
      end

      private


      attr_reader :channel, :exchange, :queue, :connection

      module ClassMethods
        def queue(queue)
          @queue_name = queue
        end

        def queue_name
          @queue_name
        end

        def exchange(exchange)
          @exchange_name = exchange
        end

        def exchange_name
          @exchange_name
        end
      end
    end
  end
end
