require 'railway_ipc/handler_store'
module RailwayIpc
  class ConsumerResponseHandlers
    include Singleton
    extend Forwardable
    def_delegators :handler_store, :registered, :register, :get

    private

    def handler_store
      @handler_store ||= RailwayIpc::HandlerStore.new
    end
  end
end
