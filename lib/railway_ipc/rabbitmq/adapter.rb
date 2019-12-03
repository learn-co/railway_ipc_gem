module RailwayIpc
  module Rabbitmq
    class Adapter
      extend Forwardable
      attr_reader :connection
      def_delegators :connection, :host, :port, :user, :pass, :automatically_recover?, :logger

      def initialize(opts)
        @connection = Bunny.new(opts)
      end
    end
  end
end
