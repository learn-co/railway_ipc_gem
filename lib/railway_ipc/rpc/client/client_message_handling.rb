module RailwayIpc
  module RPC
    module ClientMessageHandling

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      attr_reader :message, :handler
      alias_method :responder, :handler

      def registered_handlers
        ClientResponseHandlers.instance.registered
      end

      def work(payload)
        decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
        case decoded_payload.type
        when *registered_handlers
          @response_handler = response_handler_for(decoded_payload.type)
          @message = @response_handler.decode(decoded_payload.message)
        else
          @message = self.rpc_error_message.decode(decoded_payload.message)
          raise RailwayIpc::UnhandledMessageError, "#{self.class} does not know how to handle #{decoded_payload.type}"
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

      def response_handler_for(response_type)
        RPC::ClientResponseHandlers.instance.get(response_type)
      end

      module ClassMethods
        def handle_response(response_type)
          RPC::ClientResponseHandlers.instance.register(response_type)
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
