module RailwayIpc
  module Rabbitmq
    class Adapter
      extend Forwardable
      attr_reader :connection, :exchange, :queue
      def_delegators :connection, :host, :port, :user, :pass, :automatically_recover?, :logger, :start, :connected?

      def initialize(connection_options:)
        amqp_url = connection_options.amqp_url
        rabbit_adapter_class = connection_options.rabbit_adapter
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

      def create_exchange(strategy: :fanout, exchange_name:)
        @exchange = Bunny::Exchange.new(connection.channel, :fanout, @rabbit_connection_options.options[:exchange_name], durable: true)
      end

      def create_queue(queue_name:)
        @channel.queue(queue_name, durable: true).bind(exchange)
      end
    end
  end
end
