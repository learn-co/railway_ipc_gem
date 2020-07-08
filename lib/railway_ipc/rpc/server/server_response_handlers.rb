# frozen_string_literal: true

require 'railway_ipc/handler_store'
module RailwayIpc
  module RPC
    class ServerResponseHandlers
      include Singleton
      extend Forwardable

      def_delegators :handler_store, :registered, :register, :get

      private

      def handler_store
        @handler_store ||= RailwayIpc::HandlerStore.new
      end
    end
  end
end
