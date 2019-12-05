module RailwayIpc
  module RPC
    module ErrorAdapterConfigurable
      def rpc_error_adapter(rpc_error_adapter)
        @rpc_error_adapter = rpc_error_adapter
      end

      def rpc_error_adapter_class
        @rpc_error_adapter
      end
    end
  end
end
