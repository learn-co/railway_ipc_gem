# frozen_string_literal: true

RSpec.describe RailwayIpc::Rabbitmq::Payload do
  let(:message) { RailwayIpc::Messages::TestMessage.new(user_uuid: '1234') }

  describe '.encode' do
    it 'encodes the message' do
      payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      expect(payload).to eq('{"type":"RailwayIpc::Messages::TestMessage","encoded_message":"CgQxMjM0\\n"}')
    end

    it 'raises an execption if it failes to encode message' do
      expect {
        RailwayIpc::Rabbitmq::Payload.encode('something bogus')
      }.to raise_exception(RailwayIpc::InvalidProtobuf)
    end
  end

  describe '.decode' do
    it 'decodes the message' do
      payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      decoded = RailwayIpc::Rabbitmq::Payload.decode(payload)
      expect(decoded.type).to eq('RailwayIpc::Messages::TestMessage')
      expect(decoded.message).to eq("\n\x041234")
    end
  end
end
