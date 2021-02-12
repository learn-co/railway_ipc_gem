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
  it 'decodes protobuf binary encoded messages' do
    incoming_message = described_class.new(
      stubbed_pb_binary_payload,
      message_format: 'binary_protobuf'
    )
    expect(incoming_message.decoded).to eq(stubbed_protobuf)
  end

  it 'decodes protobuf json encoded messages' do
    incoming_message = described_class.new(
      stubbed_pb_json_payload,
      message_format: 'json_protobuf'
    )
    expect(incoming_message.decoded).to eq(stubbed_protobuf)
  end

  it "uses the protobuf binary decoder when a message format isn't provided" do
    incoming_message = described_class.new(stubbed_pb_binary_payload)
    expect(incoming_message.decoded).to eq(stubbed_protobuf)
  end

  it "uses the protobuf binary decoder when the message format isn't known" do
    incoming_message = described_class.new(
      stubbed_pb_binary_payload,
      message_format: 'not a real message format'
    )
    expect(incoming_message.decoded).to eq(stubbed_protobuf)
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
