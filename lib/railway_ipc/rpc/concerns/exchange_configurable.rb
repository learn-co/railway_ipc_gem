module RailwayIpc
  module RPC
    module ExchangeConfigurable
      def publish_to(exchange:)
        @exchange_name = exchange
      end

      def exchange_name
        @exchange_name
      end
    end
  end
end
