require 'railway_ipc/rabbitmq/connection'
require 'railway_ipc/rpc/server/server_response_handlers'

module RailwayIpc
  class Server
    include RailwayIpc::Rabbitmq::Connection
    attr_reader :message, :responder

    def self.rpc_error_adapter(rpc_error_adapter)
      @rpc_error_adapter = rpc_error_adapter
    end

    def self.rpc_error_adapter_class
      @rpc_error_adapter
    end

    def self.listen_to(queue:)
      queue(queue)
    end

    def self.respond_to(message_type, with:)
      RailwayIpc::RPC::ServerResponseHandlers.instance.register(handler: with, message: message_type)
    end

    def initialize(queue = nil, pool = nil, opts = {automatic_recovery: true})
      super
      @exchange = channel.default_exchange
    end

    def run
      @queue = channel.queue(self.class.queue_name, durable: true)
      subscribe_to_queue
    end

    def work(payload)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      case decoded_payload.type
      when *::RailwayIpc::RPC::ServerResponseHandlers.instance.registered
        @responder = ::RailwayIpc::RPC::ServerResponseHandlers.instance.get(decoded_payload.type).handler.new
        message_klass = ::RailwayIpc::RPC::ServerResponseHandlers.instance.get(decoded_payload.type).message
        @message = message_klass.decode(decoded_payload.message)
        responder.respond(message)
      else
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

    private

    def subscribe_to_queue
      queue.subscribe do |_delivery_info, metadata, payload|
        handle_request(payload)
      end
    end

    def handle_request(payload)
      begin
        response = work(payload)
      rescue StandardError => e
        RailwayIpc.logger.error(message, "Error responding to message. Error: #{e.class}, #{e.message}")
        response = self.class.rpc_error_adapter_class.error_message(e, message)
      ensure
        exchange.publish(
            RailwayIpc::Rabbitmq::Payload.encode(response),
            routing_key: message.reply_to
        ) if response
      end
    end
  end
end
