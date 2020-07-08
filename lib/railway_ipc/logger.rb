# frozen_string_literal: true

module RailwayIpc
  class Logger
    attr_reader :logger

    def initialize(logger)
      @logger = logger
    end

    def info(message, statement)
      logger.info("[#{message_header(message)}] #{statement}")
    end

    def warn(message, statement)
      logger.warn("[#{message_header(message)}] #{statement}")
    end

    def debug(message, statement)
      logger.debug("[#{message_header(message)}] #{statement}")
    end

    def error(message, statement)
      logger.error("[#{message_header(message)}] #{statement}")
    end

    def log_exception(e)
      logger.error(e)
    end

    def message_header(message)
      log_statement = "message type: #{message.class}, uuid: #{message.uuid}, correlation_id: #{message.correlation_id}"
      message.respond_to?(:user_uuid) ? "#{log_statement}, user_uuid: #{message.user_uuid}" : log_statement
    end
  end
end
