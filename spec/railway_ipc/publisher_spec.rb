# frozen_string_literal: true

require 'timeout'

RSpec.describe RailwayIpc::SingletonPublisher do
  let(:publisher) { RailwayIpc::TestPublisher.instance }
  let(:message)   do
    RailwayIpc::Messages::TestMessage.new(
      uuid: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid
    )
  end
  let(:encoded_message) { Base64.encode64(RailwayIpc::Messages::TestMessage.encode(message)) }

  it 'knows its exchange' do
    expect(publisher.class.exchange_name).to eq('test:events')
  end

  it 'initializes the Sneakers publisher with the correct exchange and exchange type' do
    expect(publisher.instance_variable_get(:@opts)[:exchange]).to eq('test:events')
    expect(publisher.instance_variable_get(:@opts)[:exchange_options][:type]).to eq(:fanout)
  end

  it 'auto generates a message uuid if one is not passed in' do
    message.uuid = ''
    uuid = SecureRandom.uuid

    message_with_uuid = message.clone
    message_with_uuid.uuid = uuid

    allow(SecureRandom).to receive(:uuid).and_return(uuid)
    allow_any_instance_of(Sneakers::Publisher).to receive(:publish).with(anything)
    expect(RailwayIpc::Rabbitmq::Payload).to receive(:encode).at_least(1).times.with(message_with_uuid).and_call_original
    publisher.publish(message)
  end

  it 'auto generates a correlation_id if one is not passed in' do
    message.correlation_id = ''
    correlation_id = SecureRandom.uuid

    message_with_correlation_id = message.clone
    message_with_correlation_id.correlation_id = correlation_id

    allow(SecureRandom).to receive(:uuid).and_return(correlation_id)
    allow_any_instance_of(Sneakers::Publisher).to receive(:publish).with(anything)
    expect(RailwayIpc::Rabbitmq::Payload).to receive(:encode).at_least(1).times.with(message_with_correlation_id).and_call_original
    publisher.publish(message)
  end

  it 'warns of call to old #publish method' do
    expect(RailwayIpc.logger).to \
      receive(:warn).with(
        'DEPRECATED: Use new PublisherInstance class',
        feature: 'railway_ipc_publisher'
      )

    allow_any_instance_of(Sneakers::Publisher).to receive(:publish).with(anything)
    publisher.publish(message)
  end
end

RSpec.describe RailwayIpc::Publisher, '#initialize' do
  let(:connection) { Bunny.new }

  after { cleanup! }

  it 'takes an exchange name' do
    publisher = described_class.new(
      connection: connection,
      exchange_name: 'test-exchange'
    )

    message = RailwayIpc::Messages::TestMessage.new
    publisher.publish(message)
    expect(publisher.exchange.name).to eq('test-exchange')
  end

  it 'creates a fanout exchange' do
    publisher = described_class.new(
      connection: connection,
      exchange_name: 'test-exchange'
    )

    message = RailwayIpc::Messages::TestMessage.new
    publisher.publish(message)
    expect(publisher.exchange.type).to eq(:fanout)
  end
end

RSpec.describe RailwayIpc::Publisher, 'passing options to sneakers' do
  it 'uses default connection if one is not provided' do
    expect_any_instance_of(Sneakers::Publisher).to \
      receive(:initialize).with(
        {
          exchange: 'test-exchange',
          exchange_type: :fanout
        }
      )
    described_class.new(exchange_name: 'test-exchange')
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

  let(:publisher) do
    described_class.new(
      connection: connection,
      exchange_name: 'test-exchange'
    )
  end

  after { cleanup! }

  it 'publishes a message' do
    message = RailwayIpc::Messages::TestMessage.new
    publisher.publish(message)

    payload = wait_for_payload(queue)
    expect(payload['type']).to eq('RailwayIpc::Messages::TestMessage')
  end

  it 'persists the message to the message store' do
    message = RailwayIpc::Messages::TestMessage.new

    expect {
      publisher.publish(message)
    }.to change { RailwayIpc::PublishedMessage.count }.by(1)
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
      payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['uuid']).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
    end

    it 'preserves the correlation ID if one is provided' do
      publisher.publish(message)
      payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['correlation_id']).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID)
    end
  end

  context "when required ID's are missing" do
    let(:message) { RailwayIpc::Messages::TestMessage.new }

    it "assigns a message uuid if one isn't provided" do
      publisher.publish(message)
      payload = wait_for_payload(queue)
      decoded = decode_payload(payload, RailwayIpc::Messages::TestMessage)
      expect(decoded['uuid']).to_not be_blank
    end

    it "assigns a correlation ID if one isn't provided" do
      publisher.publish(message)
      payload = wait_for_payload(queue)
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
        payload = wait_for_payload(queue)
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
        payload = wait_for_payload(queue)
      rescue Timeout::Error
        expect(payload).to be_nil
      end
    end
  end

  context 'when the publish fails' do
    let(:message) { RailwayIpc::Messages::TestMessage.new }

    before do
      allow_any_instance_of(Sneakers::Publisher).to \
        receive(:publish).and_raise(RuntimeError)
    end

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
  # We need to delete the exchange using the connection's channel; we don't
  # care about which channel because they all point to the same RabbitMQ
  # instance.
  channel = connection.create_channel
  channel.exchange_delete('test-exchange')
  channel.queue_delete('test-queue')
end

def wait_for_payload(queue)
  payload = nil
  Timeout.timeout(5) do
    _, _, payload = queue.pop until payload
  end

  JSON.parse(payload)
end

def decode_payload(payload, message_type)
  decoded_message = Base64.decode64(payload['encoded_message'])
  message_type.decode(decoded_message)
end
