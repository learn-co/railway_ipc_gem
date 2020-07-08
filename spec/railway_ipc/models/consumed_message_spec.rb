# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RailwayIpc::ConsumedMessage, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:uuid) }
    it { should validate_presence_of(:status) }

    it do
      should validate_inclusion_of(:status)
        .in_array([
                    'success',
                    'processing',
                    'ignored',
                    'unknown_message_type',
                    'failed_to_process'
                  ])
    end
  end

  describe '#processed?' do
    context 'when status is "success"' do
      it 'returns true' do
        msg = create(:consumed_message, status: 'success')
        expect(msg.processed?).to eq(true)
      end
    end

    context 'when status is anything but "success"' do
      it 'returns false' do
        msg = create(:consumed_message, status: 'processing')
        expect(msg.processed?).to eq(false)
      end
    end
  end

  describe '#create' do
    it 'saves an inserted_at date for the current time' do
      msg = create(:consumed_message, status: 'success')
      expect(msg.inserted_at.utc).to be_within(1.second).of(Time.current)
    end
  end
end

RSpec.describe RailwayIpc::ConsumedMessage, '.create_processing', type: :model do
  context 'with valid parameters' do
    let(:consumer) do
      instance_double(RailwayIpc::Consumer,
                      queue_name: 'some-queue', exchange_name: 'my-exchange')
    end

    let(:json_message) do
      {
        type: 'RailwayIpc::Messages::TestMessage',
        encoded_message: Base64.encode64(RailwayIpc::Messages::TestMessage.encode(stubbed_protobuf))
      }.to_json
    end

    let(:incoming_message) do
      RailwayIpc::IncomingMessage.new(json_message)
    end

    let(:message) { described_class.create_processing(consumer, incoming_message) }

    it 'extracts the UUID from the incoming message' do
      expect(message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
    end

    it 'sets the status' do
      expect(message.status).to eq('processing')
    end

    it 'extracts the type from the incoming message' do
      expect(message.message_type).to eq('RailwayIpc::Messages::TestMessage')
    end

    it 'extracts the user UUID from the incoming message' do
      expect(message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID)
    end

    it 'extracts the correlation UUID from the incoming message' do
      expect(message.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID)
    end

    it 'extracts the queue from the consumer' do
      expect(message.queue).to eq('some-queue')
    end

    it 'extracts the exchange from the consumer' do
      expect(message.exchange).to eq('my-exchange')
    end

    it 'extracts the raw message from the consumer' do
      expect(message.encoded_message).to eq(json_message)
    end
  end
end

RSpec.describe RailwayIpc::ConsumedMessage, '#update_with_lock', type: :model do
  let(:job) do
    instance_double(RailwayIpc::ProcessIncomingMessage::NormalMessageJob,
                    status: 'success')
  end

  let(:consumed_message) do
    described_class.new(uuid: RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
  end

  before(:each) do
    expect(job).to receive(:run)
    consumed_message.update_with_lock(job)
  end

  it { expect(consumed_message.status).to eq('success') }
  it { expect(consumed_message).to be_persisted }
end
