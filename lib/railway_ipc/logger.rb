# frozen_string_literal: true

module RailwayIpc
  # Custom logger that accepts a `device`, `level`, and `formatter`.
  # `formatter` can be any object that responds to `call`; a
  # `Logger::Formatter` is used if the argument is not provided.
  #
  # Here is an example formatter that uses `Oj` to format structured log
  # messages:
  #
  # require 'oj'
  # OjFormatter = proc do |severity, datetime, progname, data|
  #   data.merge!(
  #     name: progname,
  #     timestamp: datetime,
  #     severity: severity
  #   )
  #   Oj.dump(data, { mode: :compat, time_format: :xmlschema })
  # end
  #
  # logger = RailwayIpc::Logger.new(STDOUT, Logger::INFO, OjFormatter)
  #
  class Logger
    def initialize(device=STDOUT, level=::Logger::INFO, formatter=nil)
      @logger = ::Logger.new(device)
      @logger.level = level
      @logger.formatter = formatter if formatter
    end

    %w[fatal error warn info debug].each do |level|
      define_method(level) do |message, data={}|
        logger.send(level, data.merge(message: message))
      end
    end

    private

    attr_reader :logger
  end
end
