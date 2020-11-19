# frozen_string_literal: true

require 'singleton'

module RailwayIpc
  # RabbitMQ connection manager. Ensures there is a single RabbitMQ
  # connection and channel per thread, which prevents channel leaks.
  #
  class ConnectionManager
    include Singleton

    def initialize
      establish_connection
    end

    def establish_connection
      @connection = Bunny.new(
        host: settings[:host],
        user: settings[:user],
        pass: settings[:pass],
        port: settings[:port],
        vhost: settings[:vhost] || '/',
        logger: RailwayIpc.logger
      )
      @connection.start
      @channel = @connection.create_channel

      @connection
    end

    def channel
      return @channel if connected?

      establish_connection
      @channel
    end

    def connected?
      @connection&.connected? && @channel&.open?
    end

    private

    def amqp_url
      @amqp_url ||= ENV.fetch('RAILWAY_RABBITMQ_CONNECTION_URL', 'amqp://guest:guest@localhost:5672')
    end

    def settings
      @settings ||= AMQ::Settings.parse_amqp_url(amqp_url)
    end
  end
end
