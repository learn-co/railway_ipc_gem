# frozen_string_literal: true

require 'timeout'

RSpec.describe RailwayIpc::Publisher, '#exchange' do
  after { cleanup! }

  it 'uses the exchange name' do
    publisher = described_class.new(exchange_name: 'test-exchange')
    message = RailwayIpc::Messages::TestMessage.new
    publisher.publish(message)
    expect(publisher.exchange.name).to eq('test-exchange')
  end

  it 'creates a fanout exchange' do
    publisher = described_class.new(exchange_name: 'test-exchange')
    message = RailwayIpc::Messages::TestMessage.new
    publisher.publish(message)
    expect(publisher.exchange.type).to eq(:fanout)
  end
end

RSpec.describe RailwayIpc::Publisher, '#publish' do
  let(:connection) { Bunny.new }
  let!(:queue) do
    connection.start
    channel = connection.create_channel
    channel.exchange('test-exchange', type: :fanout, durable: true)
    channel.queue('test-queue', auto_delete: true).tap do
      channel.queue_bind('test-queue', 'test-exchange')
    end
  end

  let(:publisher) { described_class.new(exchange_name: 'test-exchange') }

  after { cleanup! }

  it 'publishes a message' do
    message = RailwayIpc::Messages::TestMessage.new
    result = publisher.publish(message)
    expect(result).to be_a(RailwayIpc::OutgoingMessage)

    _, _, payload = wait_for_payload(queue)
    expect(payload['type']).to eq('RailwayIpc::Messages::TestMessage')
  end

  it 'persists the message to the message store' do
    message = RailwayIpc::Messages::TestMessage.new

    expect {
      publisher.publish(message)
    }.to change { RailwayIpc::PublishedMessage.count }.by(1)
  end

  context 'message formats' do
    it 'sets a default message format header' do
      message = RailwayIpc::Messages::TestMessage.new
      publisher.publish(message)

      _, properties, _payload = wait_for_payload(queue)
      expect(properties.headers['message_format']).to eq('binary_protobuf')
    end

    it 'allows message format to be specified' do
      message = RailwayIpc::Messages::TestMessage.new
      publisher.publish(message, 'json_protobuf')

      _, properties, _payload = wait_for_payload(queue)
      expect(properties.headers['message_format']).to eq('json_protobuf')
    end
  end

  context "when proper ID's are provided" do
    let(:message) do
      RailwayIpc::Messages::TestMessage.new(
        uuid: RailwayIpc::SpecHelpers::DEAD_BEEF_UUID,
        correlation_id: RailwayIpc::SpecHelpers::CAFE_FOOD_UUID
      )
    end

    it 'preserves a message uuid if one is provided' do
      publisher.publish(message)
      _, _, payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['uuid']).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
    end

    it 'preserves the correlation ID if one is provided' do
      publisher.publish(message)
      _, _, payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['correlation_id']).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID)
    end
  end

  context "when required ID's are missing" do
    let(:message) { RailwayIpc::Messages::TestMessage.new }

    it "assigns a message uuid if one isn't provided" do
      publisher.publish(message)
      _, _, payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['uuid']).to_not be_blank
    end

    it "assigns a correlation ID if one isn't provided" do
      publisher.publish(message)
      _, _, payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['correlation_id']).to_not be_blank
    end
  end

  context 'when the message encoding fails' do
    let(:message) { RailwayIpc::Messages::TestMessage.new }

    before do
      allow(RailwayIpc::Messages::TestMessage).to \
        receive(:encode).and_raise(NoMethodError)
    end

    it 'raises an error' do
      expect {
        publisher.publish(message)
      }.to raise_error(RailwayIpc::InvalidProtobuf)
    end

    it 'does not store the message' do
      expect {
        publisher.publish(message)
      }.to raise_error(RailwayIpc::InvalidProtobuf)
        .and(not_change { RailwayIpc::PublishedMessage.count })
    end

    it 'does not publish the message' do
      expect {
        publisher.publish(message)
      }.to raise_error(RailwayIpc::InvalidProtobuf)

      begin
        _, _, payload = wait_for_payload(queue)
      rescue Timeout::Error
        expect(payload).to be_nil
      end
    end
  end

  context 'when the message store fails to save the message' do
    let(:message) { RailwayIpc::Messages::TestMessage.new }

    before do
      allow(RailwayIpc::PublishedMessage).to \
        receive(:create!).and_raise(ActiveRecord::RecordInvalid)
    end

    it 'raises an error' do
      expect {
        publisher.publish(message)
      }.to raise_error(RailwayIpc::FailedToStoreOutgoingMessage)
    end

    it 'does not publish the message' do
      expect {
        publisher.publish(message)
      }.to raise_error(RailwayIpc::FailedToStoreOutgoingMessage)

      begin
        _, _, payload = wait_for_payload(queue)
      rescue Timeout::Error
        expect(payload).to be_nil
      end
    end
  end

  context 'when the publish fails' do
    let(:message) { RailwayIpc::Messages::TestMessage.new }

    before { allow(publisher).to receive(:exchange).and_raise(RuntimeError) }

    it 'raises an error' do
      expect {
        publisher.publish(message)
      }.to raise_error(RuntimeError)
    end

    it 'does not store the message' do
      expect {
        publisher.publish(message)
      }.to raise_error(RuntimeError)
        .and(not_change { RailwayIpc::PublishedMessage.count })
    end
  end
end

def cleanup!
  channel = RailwayIpc::ConnectionManager.instance.channel
  channel.exchange_delete('test-exchange')
  channel.queue_delete('test-queue')
end

def wait_for_payload(queue)
  delivery_info = nil
  properties = nil
  payload = nil

  Timeout.timeout(5) do
    delivery_info, properties, payload = queue.pop until payload
  end

  [delivery_info, properties, JSON.parse(payload)]
end

def decode_payload(payload, message_type)
  decoded_message = Base64.decode64(payload['encoded_message'])
  message_type.decode(decoded_message)
end
