# frozen_string_literal: true

require 'bundler/setup'
require 'railway_ipc'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

logger = Logger.new(STDOUT)
logger.level = :fatal

RailwayIpc.configure(
  logger: logger
)
