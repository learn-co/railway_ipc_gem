require "railway_ipc/version"
require "sneakers"
require "bunny"
require "securerandom"
require "railway_ipc/logger"
require "railway_ipc/unhandled_message_error"
require "railway_ipc/response"
require "railway_ipc/rabbitmq/payload"
require "railway_ipc/null_message"
require "railway_ipc/concerns/message_handling"
require "railway_ipc/rabbitmq/connection"
require "railway_ipc/handler"
require "railway_ipc/consumer"
require "railway_ipc/publisher"
require "railway_ipc/null_handler"
require "railway_ipc/responder"
require "railway_ipc/client"
require "railway_ipc/server"
require "railway_ipc/railtie" if defined?(Rails)

module RailwayIpc
  def self.start
    Rake::Task["sneakers:run"].invoke
  end

  def self.configure(logger: ::Logger.new(STDOUT))
    @logger = RailwayIpc::Logger.new(logger)
  end

  def self.logger
    @logger || RailwayIpc::Logger.new(::Logger.new(STDOUT))
  end

  def self.bunny_logger
    logger.logger
  end

  def self.bunny_connection
    @bunny_connection ||= RailwayIpc::Rabbitmq::Connection.create_bunny_connection
  end
end
