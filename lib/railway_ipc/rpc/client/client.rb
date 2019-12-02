require 'railway_ipc/rabbitmq/connection'
require 'railway_ipc/rpc/client/client_message_handling'
require 'railway_ipc/rpc/client/client_response_handlers'

module RailwayIpc
  class Client
    include RailwayIpc::Rabbitmq::Connection
    include RailwayIpc::RPC::ClientMessageHandling

    class TimeoutError < StandardError; end

    attr_accessor :call_id, :response, :lock, :condition, :reply_queue, :request_message

    def self.request(message)
      new.request(message)
    end

    def self.publish_to(queue:, exchange:)
      queue(queue)
      exchange(exchange)
    end

    def initialize(queue=nil, pool=nil, opts={automatic_recovery: false})
      super
      setup_exchange
    end

    def request(request_message, timeout=10)
      @request_message = request_message
      setup_reply_queue
      publish_message
      poll_for_message(timeout)
      build_timeout_response unless response
      response
    end

    private

    def setup_exchange
      @exchange = Bunny::Exchange.new(channel, :fanout, self.class.exchange_name, durable: true)
      channel.queue(self.class.queue_name, durable: true).bind(exchange)
    end

    def setup_reply_queue
      @reply_queue = channel.queue('', auto_delete: true, exclusive: true)
      @call_id = request_message.correlation_id
      request_message.reply_to = reply_queue.name
    end

    def publish_message
      RailwayIpc.logger.info(request_message, 'Sending request')
      exchange.publish(RailwayIpc::Rabbitmq::Payload.encode(request_message), routing_key: '')
    end

    def poll_for_message(timeout)
      count = 0
      until response || count >= timeout do
        _delivery_info, _properties, payload = reply_queue.pop
        handle_response(payload) if payload
        count+= 1
        sleep(1)
      end
    end

    def build_timeout_response
      error = TimeoutError.new('Client timed out')
      response_message = rpc_error_adapter.error_message(error, request_message)
      self.response = RailwayIpc::Response.new(response_message, success: false)
      self.stop
    end

    def handle_response(payload)
      begin
        response_message = work(payload)
        if response_message.correlation_id == self.call_id
          RailwayIpc.logger.info(response_message, 'Handling response')
          self.response = RailwayIpc::Response.new(response_message, success: true)
          self.stop
        end
      rescue StandardError => e
        RailwayIpc.logger.error(message, "Error handling response. Error #{e.class}, message: #{e.message}")
        response_message = rpc_error_adapter.error_message(e, message)
        self.response = RailwayIpc::Response.new(response_message, success: false)
        self.stop
      end
    end
  end
end