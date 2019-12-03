require 'railway_ipc/consumer/consumer_response_handlers'
module RailwayIpc
  module ConsumerMessageHandling

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    attr_reader :message, :handler

    def registered_handlers
      ConsumerResponseHandlers.instance.registered
    end

    def work(payload)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      case decoded_payload.type
      when *registered_handlers
        @handler = handler_class(decoded_payload.type).new
        message_klass = message_class(decoded_payload.type)
      else
        @handler = RailwayIpc::NullHandler.new
        message_klass = RailwayIpc::NullMessage
      end
      @message = message_klass.decode(decoded_payload.message)
    rescue StandardError => e
      RailwayIpc.logger.log_exception(
          feature: 'railway_consumer',
          error: e.class,
          error_message: e.message,
          payload: payload
      )
      raise e
    end

    private

    def handler_class(message_type)
      handler_for(message_type).handler
    end

    def message_class(message_type)
      handler_for(message_type).message
    end

    def handler_for(message_type)
      ConsumerResponseHandlers.instance.get(message_type)
    end

    module ClassMethods
      def handle(message_type, with:)
        ConsumerResponseHandlers.instance.register(message: message_type, handler: with)
      end
    end
  end
end
