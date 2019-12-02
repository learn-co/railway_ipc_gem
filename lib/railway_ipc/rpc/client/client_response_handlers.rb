module RailwayIpc
  module RPC
    class ClientResponseHandlers
      include Singleton

      def registered
        handler_map.keys
      end

      def register(response_message)
        handler_map[response_message.to_s] = response_message
      end

      def get(response_message)
        handler_map[response_message]
      end

      private

      def handler_map
        @handler_map ||= {}
      end
    end
  end
end
