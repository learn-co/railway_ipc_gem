# frozen_string_literal: true

module RailwayIpc
  class ProcessIncomingMessage
    class UnknownMessageJob
      attr_reader :incoming_message, :logger

      def initialize(incoming_message, logger)
        @incoming_message = incoming_message
        @logger = logger
      end

      def status
        'unknown_message_type'
      end

      def run
        logger.warn(
          incoming_message.decoded,
          "Ignoring unknown message of type '#{incoming_message.type}'"
        )
      end
    end

    class IgnoredMessageJob
      attr_reader :incoming_message, :logger

      def initialize(incoming_message, logger)
        @incoming_message = incoming_message
        @logger = logger
      end

      def status
        'ignored'
      end

      def run
        logger.warn(
          incoming_message.decoded,
          "Ignoring message, no registered handler for '#{incoming_message.type}'"
        )
      end
    end

    class NormalMessageJob
      attr_reader :incoming_message, :handler, :status

      def initialize(incoming_message, handler)
        @incoming_message = incoming_message
        @handler = handler
        @status = 'not_processed'
      end

      def run
        result = handler.handle(incoming_message.decoded)
        @status = result.success? ? RailwayIpc::ConsumedMessage::STATUS_SUCCESS : RailwayIpc::ConsumedMessage::STATUS_FAILED_TO_PROCESS
      end
    end

    attr_reader :consumer, :incoming_message, :logger

    def self.call(consumer, incoming_message)
      new(consumer, incoming_message).call
    end

    def initialize(consumer, incoming_message, logger: RailwayIpc.logger)
      @consumer = consumer
      @incoming_message = incoming_message
      @logger = logger
    end

    def call
      raise_message_invalid_error unless incoming_message.valid?
      message = find_or_create_consumed_message
      return if message.processed?

      message.update_with_lock(classify_message)
    end

    private

    def raise_message_invalid_error
      error = "Message is invalid: #{incoming_message.stringify_errors}."
      logger.error(incoming_message.decoded, error)
      raise RailwayIpc::IncomingMessage::InvalidMessage.new(error)
    end

    def find_or_create_consumed_message
      RailwayIpc::ConsumedMessage.find_by(uuid: incoming_message.uuid) ||
        RailwayIpc::ConsumedMessage.create_processing(consumer, incoming_message)
    end

    # rubocop:disable Metrics/AbcSize
    def classify_message
      if incoming_message.decoded.is_a?(RailwayIpc::Messages::Unknown)
        UnknownMessageJob.new(incoming_message, logger)
      elsif handler = consumer.get_handler(incoming_message.type)
        NormalMessageJob.new(incoming_message, handler)
      else
        IgnoredMessageJob.new(incoming_message, logger)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
