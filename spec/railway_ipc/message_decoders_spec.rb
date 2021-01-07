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

  it "responds with an `UnknownMessage` when it can't find a protobuf constant" do
    decoded_message = \
      RailwayIpc::MessageDecoders::ProtobufBinaryDecoder.call('Foo', encoded_message)

    expect(decoded_message).to be_a(RailwayIpc::Messages::Unknown)
  end

  it "raises an error if it can't decode the protobuf message" do
    expect {
      RailwayIpc::MessageDecoders::ProtobufBinaryDecoder.call(type, 'invalid')
    }.to raise_error(RailwayIpc::IncomingMessage::ParserError)
  end
end
