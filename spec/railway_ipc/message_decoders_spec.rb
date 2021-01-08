# frozen_string_literal: true

RSpec.describe RailwayIpc::MessageDecoders, 'ProtobufBinaryDecoder' do
  let(:type) { 'RailwayIpc::Messages::TestMessage' }

  let(:encoded_message) do
    Base64.encode64(RailwayIpc::Messages::TestMessage.encode(stubbed_protobuf))
  end

  it 'decodes the message' do
    decoded_message = \
      RailwayIpc::MessageDecoders::ProtobufBinaryDecoder.call(type, encoded_message)

    expect(decoded_message).to eq(stubbed_protobuf)
  end

  context "when it can't find a protobuf class constant" do
    let(:decoded_message) do
      RailwayIpc::MessageDecoders::ProtobufBinaryDecoder.call('Foo', encoded_message)
    end

    it { expect(decoded_message).to be_a(RailwayIpc::Messages::Unknown) }
    it { expect(decoded_message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID) }
    it { expect(decoded_message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID) }
    it { expect(decoded_message.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID) }
  end

  it "raises an error if it can't decode the protobuf message" do
    expect {
      RailwayIpc::MessageDecoders::ProtobufBinaryDecoder.call(type, 'invalid')
    }.to raise_error(RailwayIpc::IncomingMessage::ParserError)
  end
end

RSpec.describe RailwayIpc::MessageDecoders, 'ProtobufJsonDecoder' do
  let(:type) { 'RailwayIpc::Messages::TestMessage' }

  it 'decodes the message' do
    encoded_message = stubbed_protobuf.to_h
    decoded_message = \
      RailwayIpc::MessageDecoders::ProtobufJsonDecoder.call(type, encoded_message)

    expect(decoded_message).to eq(stubbed_protobuf)
  end

  context "when it can't find a protobuf class constant" do
    let(:decoded_message) do
      RailwayIpc::MessageDecoders::ProtobufJsonDecoder.call(
        'Foo',
        stubbed_protobuf.to_h
      )
    end

    it { expect(decoded_message).to be_a(RailwayIpc::Messages::Unknown) }
    it { expect(decoded_message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID) }
    it { expect(decoded_message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID) }
    it { expect(decoded_message.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID) }
  end

  it 'raises an error if the message contains an invalid key' do
    expect {
      payload = {
        user_uuid: RailwayIpc::SpecHelpers::DEAD_BEEF_UUID,
        invalid: 'key'
      }
      RailwayIpc::MessageDecoders::ProtobufJsonDecoder.call(type, payload)
    }.to raise_error(RailwayIpc::IncomingMessage::ParserError)
  end
end
