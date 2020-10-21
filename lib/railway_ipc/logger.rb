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
    def initialize(device=$stdout, level=::Logger::INFO, formatter=nil)
      @logger = ::Logger.new(device)
      @logger.level = level
      @logger.formatter = formatter if formatter
    end

    %w[fatal error warn info debug].each do |level|
      define_method(level) do |message=nil, data={}, &block|
        data.merge!(feature: 'railway_ipc') unless data.key?(:feature)
        return logger.send(level, data.merge(message: message)) unless block

        data = message.merge(data) if message.is_a?(Hash)
        data.merge!(message: block.call)

        # This is for compatability w/ Ruby's Logger. Ruby's Logger class
        # assumes that if both a `message` argument and a block are given,
        # that the block contains the actual message. The `message` argument
        # is assumed to be the `progname`.
        #
        # https://github.com/ruby/logger/blob/master/lib/logger.rb#L471
        data.merge!(progname: message) if message.is_a?(String)
        logger.send(level, data)
      end
    end

    private

    attr_reader :logger
  end
end
