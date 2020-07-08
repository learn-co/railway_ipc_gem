# frozen_string_literal: true

RSpec.describe RailwayIpc::Rabbitmq::Payload do
  let(:message) { RailwayIpc::Messages::TestMessage.new(user_uuid: '1234') }

  describe '.encode' do
    it 'encodes the message' do
      payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      expect(payload).to eq('{"type":"RailwayIpc::Messages::TestMessage","encoded_message":"CgQxMjM0\\n"}')
    end

    it 'raises an execption if it failes to encode message' do
      expect do
        RailwayIpc::Rabbitmq::Payload.encode('something bogus')
      end.to raise_exception(RailwayIpc::InvalidProtobuf)
    end
  end
end
