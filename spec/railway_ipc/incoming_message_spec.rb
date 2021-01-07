# frozen_string_literal: true

RSpec.describe RailwayIpc::IncomingMessage, 'initialization' do
  context 'when the message is valid JSON' do
    let(:incoming_message) { described_class.new(stubbed_pb_binary_payload) }

    it 'extracts the message type' do
      expect(incoming_message.type).to eq('RailwayIpc::Messages::TestMessage')
    end

    it 'stores the raw JSON payload' do
      expect(incoming_message.payload).to eq(stubbed_pb_binary_payload)
    end
  end

  context 'when the message is invalid JSON' do
    it 'raises an error?' do
      expect {
        described_class.new('invalid-json')
      }.to raise_error(RailwayIpc::IncomingMessage::ParserError)
    end
  end
end

RSpec.describe RailwayIpc::IncomingMessage, '#decoded' do
  it 'decodes the message' do
    incoming_message = described_class.new(stubbed_pb_binary_payload)
    expect(incoming_message.decoded).to eq(stubbed_protobuf)
  end

  context "when it can't find a decoder class constant" do
    let(:incoming_message) do
      message = {
        type: 'Foo',
        encoded_message: Base64.encode64(RailwayIpc::Messages::TestMessage.encode(stubbed_protobuf))
      }.to_json
      described_class.new(message)
    end

    it 'responds with an `UnknownMessage`' do
      expect(incoming_message.decoded).to be_a(RailwayIpc::Messages::Unknown)
    end

    it { expect(incoming_message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID) }
    it { expect(incoming_message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID) }
    it { expect(incoming_message.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID) }
  end

  it "raises an error if it can't decode the protobuf message" do
    message = {
      type: 'RailwayIpc::Messages::TestMessage',
      encoded_message: 'invalid'
    }.to_json

    incoming_message = described_class.new(message)
    expect {
      incoming_message.decoded
    }.to raise_error(RailwayIpc::IncomingMessage::ParserError)
  end
end

RSpec.describe RailwayIpc::IncomingMessage, '#valid?' do
  it 'returns true if everything is ok' do
    incoming_message = described_class.new(stubbed_pb_binary_payload)
    expect(incoming_message.valid?).to eq(true)
  end

  it 'requires a message UUID' do
    protobuf = stubbed_protobuf(uuid: nil)
    incoming_message = described_class.new(stubbed_pb_binary_payload(protobuf: protobuf))
    expect(incoming_message.valid?).to eq(false)
    expect(incoming_message.errors[:uuid]).to eq('uuid is required')
  end

  it 'requires a correlation UUID' do
    protobuf = stubbed_protobuf(correlation_id: nil)
    incoming_message = described_class.new(stubbed_pb_binary_payload(protobuf: protobuf))
    expect(incoming_message.valid?).to eq(false)
    expect(incoming_message.errors[:correlation_id]).to eq('correlation_id is required')
  end
end

RSpec.describe RailwayIpc::IncomingMessage, 'decoded message delegations' do
  let(:incoming_message) { described_class.new(stubbed_pb_binary_payload) }

  it { expect(incoming_message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID) }
  it { expect(incoming_message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID) }
  it { expect(incoming_message.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID) }
end
