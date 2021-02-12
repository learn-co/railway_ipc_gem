# frozen_string_literal: true

module RailwayIpc
  class IncomingMessage
    attr_reader :type, :message_format, :payload, :parsed_payload, :errors

    def initialize(payload, message_format: nil)
      @message_format = message_format
      @parsed_payload = JSON.parse(payload)
      @type = parsed_payload['type']
      @payload = payload
      @errors = {}
    rescue JSON::ParserError => e
      raise RailwayIpc::IncomingMessage::ParserError.new(e)
    end

    def uuid
      decoded.uuid
    end

    def user_uuid
      decoded.user_uuid
    end

    def correlation_id
      decoded.correlation_id
    end

    def valid?
      errors[:uuid] = 'uuid is required' unless uuid.present?
      errors[:correlation_id] = 'correlation_id is required' unless correlation_id.present?
      errors.none?
    end

    def decoded
      @decoded ||= \
        get_decoder(message_format).call(type, parsed_payload['encoded_message'])
    end

    def stringify_errors
      errors.values.join(', ')
    end

    private

    DEFAULT_DECODER = RailwayIpc::MessageDecoders::ProtobufBinaryDecoder

    def get_decoder(name)
      {
        'binary_protobuf' => RailwayIpc::MessageDecoders::ProtobufBinaryDecoder,
        'json_protobuf' => RailwayIpc::MessageDecoders::ProtobufJsonDecoder
      }.fetch(name, DEFAULT_DECODER)
    end
  end
end
