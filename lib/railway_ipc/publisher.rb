require 'singleton'

module RailwayIpc
  class Publisher < Sneakers::Publisher
    include ::Singleton

    def self.exchange(exchange)
      @exchange_name = exchange
    end

    def self.exchange_name
      raise 'Subclass must set the exchange' unless @exchange_name
      @exchange_name
    end

    def initialize
      super(exchange: self.class.exchange_name, exchange_type: :fanout)
    end

    def publish(message)
      RailwayIpc.logger.info(message, 'Publishing message')
      super(RailwayIpc::Rabbitmq::Payload.encode(message))
    rescue RailwayIpc::InvalidProtobuf => e
      RailwayIpc.logger.error(message, 'Invalid protobuf')
      raise e
    end
  end
end
