# frozen_string_literal: true

module RailwayIpc
  module RPC
    module MessageObservationConfigurable
      def listen_to(queue:, exchange:)
        @exchange_name = exchange
        @queue_name = queue
      end

      def queue_name
        @queue_name
      end

      def exchange_name
        @exchange_name
      end
    end
  end
end
