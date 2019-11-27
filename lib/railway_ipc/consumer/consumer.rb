require 'json'
require 'base64'
require 'railway_ipc/consumer/consumer_message_handling'

module RailwayIpc
  class Consumer
    include Sneakers::Worker
    include RailwayIpc::ConsumerMessageHandling

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
