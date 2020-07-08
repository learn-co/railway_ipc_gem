# frozen_string_literal: true

module RailwayIpc
  module Rabbitmq
    class Payload
      attr_reader :type, :message

      def self.encode(message)
        type = message.class.to_s
        begin
          message = Base64.encode64(message.class.encode(message))
        rescue NoMethodError
          raise RailwayIpc::InvalidProtobuf.new("Message #{message} is not a valid protobuf")
        end
        new(type, message).to_json
      end

      def self.decode(message)
        message = JSON.parse(message)
        type = message['type']
        message = Base64.decode64(message['encoded_message'])
        new(type, message)
      end

      def initialize(type, message)
        @type = type
        @message = message
      end

      def to_json
        {
          type: type,
          encoded_message: message
        }.to_json
      end
    end
  end
end
