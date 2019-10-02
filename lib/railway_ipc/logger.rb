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
      "message type: #{message.class}, uuid: #{message.uuid}, correlation_id: #{message.correlation_id},  user_uuid: #{message.user_uuid}"
    end
  end
end
