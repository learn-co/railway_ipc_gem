# frozen_string_literal: true

module RailwayIpc
  class Publisher
    attr_reader :exchange_name, :message_store

    def initialize(opts={})
      @exchange_name = opts.fetch(:exchange_name)
      @message_store = opts.fetch(:message_store, RailwayIpc::PublishedMessage)
    end

    # rubocop:disable Metrics/AbcSize
    def publish(message, format='binary_protobuf')
      outgoing_message = OutgoingMessage.new(message, exchange_name, format)
      stored_message = message_store.store_message(outgoing_message)
      RailwayIpc.logger.info('Publishing message', log_message_options(message))
      exchange.publish(outgoing_message.encoded, headers: { message_format: format })
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

    def exchange
      @exchange ||= channel.exchange(exchange_name, type: :fanout, durable: true, auto_delete: false, arguments: {})
    end

    private

    def channel
      RailwayIpc::ConnectionManager.instance.channel
    end

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
