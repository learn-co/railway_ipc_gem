require "railway_ipc/rabbitmq/connection"
require "railway_ipc/concerns/server_message_handling"

module RailwayIpc
  class Server
    include RailwayIpc::Rabbitmq::Connection
    include RailwayIpc::Concerns::ServerMessageHandling

    def self.listen_to(queue:)
      queue(queue)
    end

    def initialize(queue=nil, pool=nil, opts={automatic_recovery: true})
      super
      @exchange = channel.default_exchange
    end

    def run
      @queue = channel.queue(self.class.queue_name, durable: true)
      subscribe_to_queue
    end

    def work(payload)
      super
      responder.respond(message)
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
        response = self.rpc_error_adapter.error_message(e, message)
      ensure
        exchange.publish(
          RailwayIpc::Rabbitmq::Payload.encode(response),
          routing_key: message.reply_to
        ) if response
      end
    end
  end
end
