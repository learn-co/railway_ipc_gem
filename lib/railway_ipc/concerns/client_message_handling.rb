module RailwayIpc
  module Concerns
    module ClientMessageHandling

      HANDLERS = {}

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      attr_reader :message, :handler
      alias_method :responder, :handler

      def work(payload)
        # can fail
        decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
        # Conditional here probably due to Message handling being used in multiple cases
        @handler = handler_class(decoded_payload.type).new if handler_class(decoded_payload.type)
        message_klass = message_class(decoded_payload.type)
        if !message_klass
          @message = self.rpc_error_message.decode(decoded_payload.message)
          raise RailwayIpc::UnhandledMessageError, "#{self.class} does not know how to handle #{decoded_payload.type}"
        else

          @message = message_klass.decode(decoded_payload.message)
        end
      rescue StandardError => e
        RailwayIpc.logger.log_exception({
          feature: "railway_consumer",
          error: e.class,
          error_message: e.message,
          payload: payload
        })
        raise e
      end

      def rpc_error_adapter
        self.class.rpc_error_adapter_class
      end

      def rpc_error_message
        self.class.rpc_error_message_class
      end

      private

      def handler_class(message_type)
        if handler = handler_for(message_type)
          handler.fetch(:handler_class)
        else
          null_handler
        end
      end

      def handler_for(message_type)
        # StoredHandlers.get(message_type) || NullHandlerManifest.new
        HANDLERS[message_type]
      end


      def message_class(message_type)
        if handler = handler_for(message_type)
          handler.fetch(:message_class)
        else
          null_message
        end
      end

      def null_message
        self.class.ancestors
          .grep(RailwayIpc::Concerns::ClientMessageHandling::ClassMethods)
          .reverse
          .first
          .null_message_class
      end


      def null_handler
        self.class.ancestors
          .grep(RailwayIpc::Concerns::ClientMessageHandling::ClassMethods)
          .reverse
          .first
          .null_handler_class
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

        def handle_null_messages_with(null_handler)
          @null_handler = null_handler
        end

        def null_handler_class
          p self
          @null_handler
        end

        def handle_unknown_messages_as(null_message)
          @null_message = null_message
        end

        def null_message_class
          @null_message
        end

        def handle(message_type, with:nil)
          HANDLERS[message_type.to_s] = HandlerManifest.new(with, message_type)
        end

        RailwayIpc::HandlerManifest = Struct.new(:handler_class, :message_class) do
          def fetch(key, default=nil)
            self[key] || default
          end
        end
        alias_method :respond_to, :handle
        alias_method :handle_response, :handle
      end
    end
  end
end
