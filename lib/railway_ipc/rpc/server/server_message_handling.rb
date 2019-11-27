module RailwayIpc
  module RPC
    module ServerMessageHandling
      HANDLERS = {}

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      attr_reader :message, :responder

      def registered_handlers
        HANDLERS.keys
      end

      def work(payload)
        decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
        case decoded_payload.type
        when *registered_handlers
          @responder = handler_class(decoded_payload.type).new
          message_klass = message_class(decoded_payload.type)
          @message = message_klass.decode(decoded_payload.message)
        else
          @message = rpc_error_message.decode(decoded_payload.message)
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

      def handler_for(message_type)
        HANDLERS[message_type]
      end

      def handler_class(message_type)
        handler_for(message_type).handler_class
      end

      def message_class(message_type)
        handler_for(message_type).message_class
      end

      module ClassMethods
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

        def respond_to(message_type, with:)
          HANDLERS[message_type.to_s] = ServerHandlerManifest.new(with, message_type)
        end

        RailwayIpc::ServerHandlerManifest = Struct.new(:handler_class, :message_class)
      end
    end
  end
end
