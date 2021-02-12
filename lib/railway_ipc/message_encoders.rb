# frozen_string_literal: true

module RailwayIpc
  module MessageEncoders
    ProtobufBinaryEncoder = lambda do |message|
      {
        type: message.type,
        encoded_message: Base64.encode64(message.proto.class.encode(message.proto))
      }.to_json
    rescue NoMethodError
      raise RailwayIpc::InvalidProtobuf.new("Message #{message} is not a valid protobuf")
    end

    ProtobufJsonEncoder = lambda do |message|
      {
        type: message.type,
        encoded_message: message.proto.to_h
      }.to_json
    rescue NoMethodError
      raise RailwayIpc::InvalidProtobuf.new("Message #{message} is not a valid protobuf")
    end
  end
end
