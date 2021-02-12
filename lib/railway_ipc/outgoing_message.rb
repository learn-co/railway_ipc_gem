# frozen_string_literal: true

module RailwayIpc
  class OutgoingMessage
    extend Forwardable

    attr_reader :proto, :exchange, :format

    def_delegators :@proto, :uuid, :user_uuid, :correlation_id

    def initialize(proto, exchange, format=nil)
      proto.uuid = SecureRandom.uuid if proto.uuid.blank?
      proto.correlation_id = SecureRandom.uuid if proto.correlation_id.blank?
      @proto = proto
      @exchange = exchange
      @format = format
    end

    def type
      proto.class.to_s
    end

    def encoded
      @encoded ||= encoder.call(self)
    end

    private

    DEFAULT_ENCODER = RailwayIpc::MessageEncoders::ProtobufBinaryEncoder

    def encoder
      {
        'binary_protobuf' => RailwayIpc::MessageEncoders::ProtobufBinaryEncoder,
        'json_protobuf' => RailwayIpc::MessageEncoders::ProtobufJsonEncoder
      }.fetch(format, DEFAULT_ENCODER)
    end
  end
end
