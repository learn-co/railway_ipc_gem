module RailwayIpc
  module RPC
    class ResponceHandlers
      include Singleton

      def register(message)
        handler_map[message.to_s] = message
      end

      def get(message)
        handler_map[message]
      end

      private

      def handler_map
        @handler_map ||= {}
      end
    end
  end
end
