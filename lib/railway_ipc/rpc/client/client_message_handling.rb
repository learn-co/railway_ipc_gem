module RailwayIpc
  module RPC
    module ClientMessageHandling

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      attr_reader :message, :handler
      alias_method :responder, :handler

      def work(payload)
        decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
        @response_handler = responder_class(decoded_payload.type)
        if !@response_handler
          @message = self.rpc_error_message.decode(decoded_payload.message)
          raise RailwayIpc::UnhandledMessageError, "#{self.class} does not know how to handle #{decoded_payload.type}"
        else
          @message = @response_handler.decode(decoded_payload.message)
        end
      rescue StandardError => e
        RailwayIpc.logger.log_exception(
          feature: 'railway_consumer',
          error: e.class,
          error_message: e.message,
          payload: payload
        )
        raise e
      end

      def rpc_error_adapter
        self.class.rpc_error_adapter_class
      end

      def rpc_error_message
        self.class.rpc_error_message_class
      end

      private

      def responder_class(payload)
        RPC::ResponseHandlers.instance.get(payload)
      end

      module ClassMethods
        def handle_response(message_type)
          RPC::ResponseHandlers.instance.register(message_type)
        end

        def rpc_error_message(rpc_error_message_class)
          @rpc_error_message_class = rpc_error_message_class
        end

        def rpc_error_message_class
          @rpc_error_message_class
        end

        def rpc_error_adapter(rpc_error_adapter)
          @rpc_error_adapter_class = rpc_error_adapter
        end

        def rpc_error_adapter_class
          @rpc_error_adapter_class
        end
      end
    end
  end
end
