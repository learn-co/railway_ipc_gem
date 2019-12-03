require 'bunny'
module RailwayIpc
  module Rabbitmq
    RabbitConnectionOptions = Struct.new(:amqp_url, :rabbit_adapter_class, :options)
    class TemporaryConnection

      attr_reader :rabbit_connection
      def create_bunny_connection(connection_options)
        amqp_url = connection_options.amqp_url
        rabbit_adapter_class = connection_options.rabbit_adapter_class
        opts = connection_options.options

        settings = AMQ::Settings.parse_amqp_url(amqp_url)
        rabbit_adapter_class.new(
            host: settings[:host],
            user: settings[:user],
            pass: settings[:pass],
            port: settings[:port],
            automatic_recovery: opts[:automatic_recovery],
            logger: RailwayIpc.bunny_logger)
      end

      def default_connection_options
        RabbitConnectionOptions.new(ENV["RAILWAY_RABBITMQ_CONNECTION_URL"], Bunny, {automatic_recovery: true})
      end

      def initialize(queue=nil, pool=nil, opts={automatic_recovery: true}, connection_options: default_connection_options)
        @rabbit_connection = create_bunny_connection(connection_options)
      end

      def start
        connection.start
        @channel = connection.create_channel
      end

      def stop
        channel.close
        connection.close
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
