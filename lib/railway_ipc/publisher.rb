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

    def publish(message, published_message_store=RailwayIpc::PublishedMessage)
      ensure_message_uuid(message)
      ensure_correlation_id(message)
      RailwayIpc.logger.info(message, 'Publishing message')

      result = super(RailwayIpc::Rabbitmq::Payload.encode(message))
      published_message_store.store_message(self.class.exchange_name, message)
      result
    rescue RailwayIpc::InvalidProtobuf => e
      RailwayIpc.logger.error(message, 'Invalid protobuf')
      raise e
    end

    private

    def ensure_message_uuid(message)
      if message.uuid.blank?
        message.uuid = SecureRandom.uuid
        message
      else
        message
      end
    end

    def ensure_correlation_id(message)
      if message.correlation_id.blank?
        message.correlation_id = SecureRandom.uuid
        message
      else
        message
      end
    end
  end
end
