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
  end
end
