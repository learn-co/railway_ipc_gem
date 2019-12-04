require 'railway_ipc/rabbitmq/connection'
require 'railway_ipc/rpc/client/client_response_handlers'

module RailwayIpc
  module RPC
    class ErrorHandler
      attr_accessor :adapter_class
    end
  end
end
module RailwayIpc
  class Client
    #include RailwayIpc::Rabbitmq::Connection
    def self.exchange(exchange)
      @exchange_name = exchange
    end

    def self.exchange_name
      @exchange_name
    end
    attr_reader :message, :responder
    attr_accessor :call_id, :response, :request_message

    def self.error_handler
      @error_handler ||= RailwayIpc::RPC::ErrorHandler.new
    end

    def self.rpc_error_message(_rpc_error_message_class)
      ;
    end

    def self.rpc_error_adapter(rpc_error_adapter)
      error_handler.adapter_class = rpc_error_adapter
    end

    def self.rpc_error_adapter_class
      error_handler.adapter_class
    end

    def self.request(message)
      new.request(message)
    end

    def self.publish_to(exchange:)
      exchange(exchange)
    end

    def self.handle_response(response_type)
      RPC::ClientResponseHandlers.instance.register(response_type)
    end

    def initialize(opts = {automatic_recovery: false}, rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
      @rabbit_connection = rabbit_adapter.new(exchange_name: self.class.exchange_name, options: opts)
    end

    def request(request_message, timeout = 10)
      @rabbit_connection
          .connect
          .create_exchange
      @request_message = request_message
      setup_reply_queue
      publish_message
      await_response(timeout)
      response
    end

    private

    def setup_exchange
      @exchange = Bunny::Exchange.new(channel, :fanout, self.class.exchange_name, durable: true)
    end

    def setup_reply_queue
      @rabbit_connection.create_queue(auto_delete: true, exclusive: true)
      @call_id = request_message.correlation_id
      request_message.reply_to = @rabbit_connection.queue.name
    end

    def publish_message
      RailwayIpc.logger.info(request_message, 'Sending request')
      @rabbit_connection.publish(RailwayIpc::Rabbitmq::Payload.encode(request_message), routing_key: '')
    end

    def await_response(timeout)
      @rabbit_connection.check_for_message(timeout: timeout) do |_, _, payload|
        process_response(payload)
      end
    rescue RailwayIpc::Rabbitmq::Adapter::TimeoutError => error
      error.message = "Client timed out"
      response_message = self.class.rpc_error_adapter_class.error_message(error, request_message)
      self.response = RailwayIpc::Response.new(response_message, success: false)
      @rabbit_connection.disconnect
    rescue StandardError => e
      RailwayIpc.logger.log_exception(
          feature: 'railway_consumer',
          error: e.class,
          error_message: e.message,
          payload: payload
      )
      response_message = self.class.rpc_error_adapter_class.error_message(e, message)
      self.response = RailwayIpc::Response.new(response_message, success: false)
      @rabbit_connection.disconnect
    end

    def process_response(response)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      case decoded_payload.type
      when *::RailwayIpc::RPC::ClientResponseHandlers.instance.registered
        @response_handler = RPC::ClientResponseHandlers.instance.get(decoded_payload.type)
        @message = @response_handler.decode(decoded_payload.message)
        if @message.correlation_id == self.call_id
          RailwayIpc.logger.info(decoded_payload, 'Handling response')
          self.response = RailwayIpc::Response.new(decoded_payload, success: true)
          @rabbit_connection.disconnect
        end
      else
        raise RailwayIpc::UnhandledMessageError, "#{self.class} does not know how to handle #{decoded_payload.type}"
      end
    end
  end
end
