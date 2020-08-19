# frozen_string_literal: true

require 'singleton'

module RailwayIpc
  class SingletonPublisher < Sneakers::Publisher
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
      RailwayIpc.logger.warn('DEPRECATED: Use new PublisherInstance class', log_message_options)
      ensure_message_uuid(message)
      ensure_correlation_id(message)
      RailwayIpc.logger.info('Publishing message', log_message_options(message))
      result = super(RailwayIpc::Rabbitmq::Payload.encode(message))
      published_message_store.store_message(self.class.exchange_name, message)
      result
    rescue RailwayIpc::InvalidProtobuf => e
      RailwayIpc.logger.error('Invalid protobuf', log_message_options(message))
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

    def log_message_options(message=nil)
      options = { feature: 'railway_ipc_publisher', exchange: self.class.exchange_name }
      message.nil? ? options : options.merge(protobuf: { type: message.class, data: message })
    end
  end
end

module RailwayIpc
  class Publisher < Sneakers::Publisher
    attr_reader :exchange_name, :message_store

    def initialize(opts={})
      @exchange_name = opts.fetch(:exchange_name)
      @message_store = opts.fetch(:message_store, RailwayIpc::PublishedMessage)
      connection = opts.fetch(:connection, nil)
      options = {
        exchange: exchange_name,
        connection: connection,
        exchange_type: :fanout
      }.compact
      super(options)
    end

    # rubocop:disable Metrics/AbcSize
    def publish(message)
      message.uuid = SecureRandom.uuid if message.uuid.blank?
      message.correlation_id = SecureRandom.uuid if message.correlation_id.blank?
      RailwayIpc.logger.info('Publishing message', log_message_options(message))

      stored_message = message_store.store_message(exchange_name, message)
      super(RailwayIpc::Rabbitmq::Payload.encode(message))
    rescue RailwayIpc::InvalidProtobuf => e
      RailwayIpc.logger.error('Invalid protobuf', log_message_options(message))
      raise e
    rescue ActiveRecord::RecordInvalid => e
      RailwayIpc.logger.error('Failed to store outgoing message', log_message_options(message))
      raise RailwayIpc::FailedToStoreOutgoingMessage.new(e)
    rescue StandardError => e
      stored_message&.destroy
      raise e
    end
    # rubocop:enable Metrics/AbcSize

    private

    def log_message_options(message)
      {
        feature: 'railway_ipc_publisher',
        exchange: exchange_name,
        protobuf: {
          type: message.class,
          data: message
        }
      }
    end
  end
end
