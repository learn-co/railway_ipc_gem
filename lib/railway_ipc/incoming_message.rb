# frozen_string_literal: true

module RailwayIpc
  class IncomingMessage
    attr_reader :type, :payload, :parsed_payload, :errors

    def initialize(payload)
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
      @decoded ||= RailwayIpc::MessageDecoders::ProtobufBinaryDecoder.call(type, parsed_payload['encoded_message'])
    end

    def stringify_errors
      errors.values.join(', ')
    end
  end
end
