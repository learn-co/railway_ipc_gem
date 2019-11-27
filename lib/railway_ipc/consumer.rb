require 'json'
require 'base64'
require "railway_ipc/null_handler"

module RailwayIpc
  class Consumer
    include Sneakers::Worker
    include RailwayIpc::Concerns::MessageHandling

    handle_unknown_messages_as RailwayIpc::NullMessage
    handle_null_messages_with RailwayIpc::NullHandler

    def self.listen_to(queue:, exchange:)
      from_queue queue,
                 exchange: exchange,
                 durable: true,
                 exchange_type: :fanout,
                 connection: RailwayIpc.bunny_connection
    end

    def work(payload)
      super
      handler.handle(message)
    end
  end
end
