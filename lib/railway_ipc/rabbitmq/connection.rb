require 'bunny'
module RailwayIpc
  module Rabbitmq
    module Connection

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def self.create_bunny_connection(opts={automatic_recovery: true})
        settings = AMQ::Settings.parse_amqp_url(ENV["RAILWAY_RABBITMQ_CONNECTION_URL"])
        Bunny.new(
          host: settings[:host],
          user: settings[:user],
          pass: settings[:pass],
          port: settings[:port],
          automatic_recovery: opts[:automatic_recovery],
          logger: RailwayIpc.bunny_logger)
      end

      def initialize(queue=nil, pool=nil, opts={automatic_recovery: true})
        @connection = RailwayIpc::Rabbitmq::Connection.create_bunny_connection(opts)
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
