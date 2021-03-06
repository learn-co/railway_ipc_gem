# frozen_string_literal: true

require 'railway_ipc/version'
require 'sneakers'
require 'sneakers/spawner'
require 'bunny'
require 'active_record'
require 'singleton'
require 'railway_ipc/logger'
require 'railway_ipc/unhandled_message_error'
require 'railway_ipc/response'
require 'railway_ipc/rabbitmq/payload'
require 'railway_ipc/unknown_message.pb'
require 'railway_ipc/rabbitmq/adapter'
require 'railway_ipc/handler'
require 'railway_ipc/handler_store'
require 'railway_ipc/message_encoders'
require 'railway_ipc/message_decoders'
require 'railway_ipc/incoming_message'
require 'railway_ipc/outgoing_message'
require 'railway_ipc/connection_manager'
require 'railway_ipc/publisher'
require 'railway_ipc/responder'
require 'railway_ipc/rpc/rpc'
require 'railway_ipc/consumer/consumer'
require 'railway_ipc/consumer/process_incoming_message'
require 'railway_ipc/models/published_message'
require 'railway_ipc/models/consumed_message'
require 'railway_ipc/railtie' if defined?(Rails)
require 'railway_ipc/errors'

module RailwayIpc
  def self.start
    Rake::Task['sneakers:run'].invoke
  end

  def self.spawn
    Sneakers::Spawner.spawn
  end

  def self.configure(log_device=$stdout, level=::Logger::INFO, log_formatter=nil)
    @logger = RailwayIpc::Logger.new(log_device, level, log_formatter)
  end

  def self.logger
    @logger || RailwayIpc::Logger.new($stdout)
  end

  def self.bunny_connection
    @bunny_connection ||= RailwayIpc::Rabbitmq::Adapter.new(
      exchange_name: 'default',
      options: { automatic_recovery: true }
    ).connection
  end
end
