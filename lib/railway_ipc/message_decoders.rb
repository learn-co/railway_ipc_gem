# frozen_string_literal: true

module RailwayIpc
  module MessageDecoders
    ProtobufBinaryDecoder = lambda do |type, encoded_message|
      protobuf_msg = Base64.decode64(encoded_message)
      protobuf_klass = Kernel.const_get(type)
      protobuf_klass.decode(protobuf_msg)
    rescue Google::Protobuf::ParseError => e
      raise RailwayIpc::IncomingMessage::ParserError.new(e)
    rescue NameError
      RailwayIpc::Messages::Unknown.decode(protobuf_msg)
    end

    ProtobufJsonDecoder = lambda do |type, message_hash|
      protobuf_klass = Kernel.const_get(type)
      protobuf_klass.new(message_hash)
    rescue ArgumentError => e
      raise RailwayIpc::IncomingMessage::ParserError.new(e)
    rescue NameError
      # NOTE: I didn't realize this until I made this ProtobufJsonDecoder, but
      # the ProtobufBinaryDecoder will ignore any unknown keys -- which is
      # probably not what we want. I'm coding this the same way as the binary
      # protobuf version for consistency, but we should re-think how we want to
      # handle this situation. -BN
      RailwayIpc::Messages::Unknown.new(
        user_uuid: message_hash.fetch(:user_uuid, ''),
        correlation_id: message_hash.fetch(:correlation_id, ''),
        uuid: message_hash.fetch(:uuid, ''),
        context: message_hash.fetch(:context, {})
      )
    end
  end
end
