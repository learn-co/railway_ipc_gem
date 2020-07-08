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
