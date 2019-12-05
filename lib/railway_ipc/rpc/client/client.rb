require 'railway_ipc/rabbitmq/connection'
require 'railway_ipc/rpc/client/client_response_handlers'
require 'railway_ipc/rpc/concerns/exchange_configurable'
require 'railway_ipc/rpc/concerns/error_adapter_configurable'
module RailwayIpc
  class Client
    attr_accessor :response_message, :request_message
    attr_reader :rabbit_adapter, :rabbit_connection
    extend RailwayIpc::RPC::ExchangeConfigurable
    extend RailwayIpc::RPC::ErrorAdapterConfigurable

    def self.request(message)
      new(message).request
    end

    def self.handle_response(response_type)
      RPC::ClientResponseHandlers.instance.register(response_type)
    end

    def initialize(request_message, opts = {automatic_recovery: false}, rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
      @rabbit_connection = rabbit_adapter.new(exchange_name: self.class.exchange_name, options: opts)
      @rabbit_adapter = rabbit_adapter
      @request_message = request_message
    end

    def request(timeout = 10)
      setup_rabbit_connection
      attach_reply_queue_to_message
      publish_message
      await_response(timeout)
      response_message
    end

    def registered_handlers
      RailwayIpc::RPC::ClientResponseHandlers.instance.registered
    end

    def process_payload(response)
      decoded_payload = decode_payload(response)
      case decoded_payload.type
      when *registered_handlers
        message = get_handler_for_message(decoded_payload).decode(decoded_payload.message)
        RailwayIpc.logger.info(decoded_payload, 'Handling response')
        RailwayIpc::Response.new(message, success: true)
      else
        raise RailwayIpc::UnhandledMessageError, "#{self.class} does not know how to handle #{decoded_payload.type}"
      end
    end

    def setup_rabbit_connection
      rabbit_connection
          .connect
          .create_exchange
          .create_queue(auto_delete: true, exclusive: true)
    end

    def await_response(timeout)
      payload = nil
      rabbit_connection.check_for_message(timeout: timeout) do |_, _, payload|
        self.response_message = process_payload(payload)
      end
    rescue RailwayIpc::Rabbitmq::Adapter::TimeoutError, RailwayIpc::UnhandledMessageError => e
      log_exception(e, decode_for_error(payload))
      self.response_message = RailwayIpc::Response.new(decode_for_error(payload), success: false)
      raise e
    ensure
      rabbit_connection.disconnect
    end

    private

    def get_handler_for_message(decoded_payload)
      RailwayIpc::RPC::ClientResponseHandlers.instance.get(decoded_payload.type)
    end

    def decode_payload(response)
      RailwayIpc::Rabbitmq::Payload.decode(response)
    end

    def attach_reply_queue_to_message
      request_message.reply_to = rabbit_connection.queue.name
    end

    def publish_message
      RailwayIpc.logger.info(request_message, 'Sending request')
      rabbit_connection.publish(RailwayIpc::Rabbitmq::Payload.encode(request_message), routing_key: '')
    end

    def decode_for_error(payload)
      return "Payload not available" unless payload
      self.class.rpc_error_adapter_class.error_message(payload, self.request_message)
    end

    def log_exception(error, payload)
      RailwayIpc.logger.log_exception(
          feature: 'railway_consumer',
          error: error.class,
          error_message: error.message,
          payload: payload
      )
    end
  end
end
