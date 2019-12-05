module RailwayIpc
  module RPC
    module MessageObservationConfigurable
      def listen_to(queue:)
        @queue_name = queue
      end

      def queue_name
        @queue_name
      end
    end
  end
end
