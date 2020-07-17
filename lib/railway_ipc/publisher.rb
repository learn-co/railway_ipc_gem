# frozen_string_literal: true

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
      message.uuid = SecureRandom.uuid if message.uuid.blank?
      message
    end

    def ensure_correlation_id(message)
      message.correlation_id = SecureRandom.uuid if message.correlation_id.blank?
      message
    end
  end
end

module RailwayIpc
  class PublisherInstance < Sneakers::Publisher
    attr_reader :exchange_name, :message_store

    def initialize(exchange_name:, connection: nil, message_store: RailwayIpc::PublishedMessage)
      @exchange_name = exchange_name
      @message_store = message_store
      super(exchange: exchange_name, connection: connection, exchange_type: :fanout)
    end

    # rubocop:disable Metrics/AbcSize
    def publish(message)
      message.uuid = SecureRandom.uuid if message.uuid.blank?
      message.correlation_id = SecureRandom.uuid if message.correlation_id.blank?
      RailwayIpc.logger.info(message, 'Publishing message')

      stored_message = message_store.store_message(exchange_name, message)
      super(RailwayIpc::Rabbitmq::Payload.encode(message))
    rescue RailwayIpc::InvalidProtobuf => e
      RailwayIpc.logger.error(message, 'Invalid protobuf')
      raise e
    rescue ActiveRecord::RecordInvalid => e
      RailwayIpc.logger.error(message, 'Failed to store outgoing message')
      raise RailwayIpc::FailedToStoreOutgoingMessage.new(e)
    rescue StandardError => e
      stored_message&.destroy
      raise e
    end
    # rubocop:enable Metrics/AbcSize
  end
end
