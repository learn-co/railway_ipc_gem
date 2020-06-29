require 'railway_ipc/version'
require 'sneakers'
require 'bunny'
require 'active_record'
require 'railway_ipc/version'
require 'railway_ipc/errors'
require 'railway_ipc/logger'
require 'railway_ipc/unhandled_message_error'
require 'railway_ipc/response'
require 'railway_ipc/rabbitmq/payload'
require 'railway_ipc/base_message.pb'
require 'railway_ipc/rabbitmq/adapter'
require 'railway_ipc/handler'
require 'railway_ipc/handler_store'
require 'railway_ipc/publisher'
require 'railway_ipc/responder'
require 'railway_ipc/rpc/rpc'
require 'railway_ipc/consumer/consumer'
require 'railway_ipc/models/published_message'
require 'railway_ipc/models/consumed_message'
require 'railway_ipc/railtie' if defined?(Rails)

module RailwayIpc
  def self.start
    Rake::Task['sneakers:run'].invoke
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
    @bunny_connection ||= RailwayIpc::Rabbitmq::Adapter.new(
      exchange_name: 'default',
      options: { automatic_recovery: true }
    ).connection
  end
end
