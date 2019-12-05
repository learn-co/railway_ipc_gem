require 'bunny'
module RailwayIpc
  module Rabbitmq
    module Connection
      def self.create_bunny_connection(opts={automatic_recovery: true})
        settings = AMQ::Settings.parse_amqp_url(ENV["RAILWAY_RABBITMQ_CONNECTION_URL"])
        Bunny.new(
          host: settings[:host],
          user: settings[:user],
          pass: settings[:pass],
          port: settings[:port],
          automatic_recovery: opts[:automatic_recovery],
          logger: RailwayIpc.bunny_logger)
      end
    end
  end
end
