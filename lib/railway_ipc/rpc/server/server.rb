require 'railway_ipc/rpc/server/server_response_handlers'
require 'railway_ipc/rpc/concerns/error_adapter_configurable'
require 'railway_ipc/rpc/concerns/message_observation_configurable'

module RailwayIpc
  class Server
    extend RailwayIpc::RPC::ErrorAdapterConfigurable
    extend RailwayIpc::RPC::MessageObservationConfigurable
    attr_reader :message, :responder

    def self.respond_to(message_type, with:)
      RailwayIpc::RPC::ServerResponseHandlers.instance.register(handler: with, message: message_type)
    end

    def initialize(opts = {automatic_recovery: true}, rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
      @rabbit_connection = rabbit_adapter.new(queue_name: self.class.queue_name, exchange_name: "default", options: opts)
    end

    def run
      @rabbit_connection
          .connect
          .create_exchange
          .create_queue(durable: true)
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
      @rabbit_connection.subscribe do |_delivery_info, _metadata, payload|
        handle_request(payload)
      end
    end

    def handle_request(payload)
      response = work(payload)
    rescue StandardError => e
      RailwayIpc.logger.error(message, "Error responding to message. Error: #{e.class}, #{e.message}")
      response = self.class.rpc_error_adapter_class.error_message(e, message)
    ensure
      @rabbit_connection.publish(
          RailwayIpc::Rabbitmq::Payload.encode(response),
          routing_key: message.reply_to
      ) if response
    end
  end
end
