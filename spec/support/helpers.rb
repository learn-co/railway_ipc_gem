# frozen_string_literal: true

module RailwayIpc
  module SpecHelpers
    DEAD_BEEF_UUID = 'deadbeef-dead-dead-dead-deaddeafbeef'
    CAFE_FOOD_UUID = 'cafef00d-cafe-cafe-cafe-cafef00dcafe'
    BAAD_FOOD_UUID = 'baadf00d-baad-baad-baad-baadbaadf00d'

    def stubbed_protobuf(uuid: DEAD_BEEF_UUID, user_uuid: BAAD_FOOD_UUID, correlation_id: CAFE_FOOD_UUID)
      RailwayIpc::Messages::TestMessage.new(
        uuid: uuid,
        user_uuid: user_uuid,
        correlation_id: correlation_id,
        data: { param: '42' }
      )
    end

    def stubbed_pb_binary_payload(type: 'RailwayIpc::Messages::TestMessage', protobuf: stubbed_protobuf)
      {
        type: type,
        encoded_message: Base64.encode64(RailwayIpc::Messages::TestMessage.encode(protobuf))
      }.to_json
    end

    class FakeLogger
      attr_reader :messages

      def initialize
        @messages = Hash.new { |h, k| h[k] = [] }
      end

      %i[warn error].each do |method|
        define_method(method) do |message|
          messages[method] << message
        end
      end
    end

    class FakeHandler
      attr_reader :handled_message, :result

      def initialize
        @result = OpenStruct.new({ success?: true })
      end

      def result=(value)
        @result = OpenStruct.new({ success?: value })
      end

      def handle(message)
        @handled_message = message
        result
      end

      def called?
        !handled_message.nil?
      end
    end
  end
end
