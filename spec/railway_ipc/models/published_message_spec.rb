# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RailwayIpc::PublishedMessage, 'validations', type: :model do
  it { should validate_presence_of(:uuid) }
  it { should validate_presence_of(:status) }
end

RSpec.describe RailwayIpc::PublishedMessage, '.store_message', type: :model do
  it 'successfully saves the message' do
    proto = stubbed_protobuf
    message = RailwayIpc::OutgoingMessage.new(proto, 'test:events', 'json_protobuf')

    expect {
      stored_message = described_class.store_message(message)
      expected_encoded = '{"type":"RailwayIpc::Messages::TestMessage",' \
                         '"encoded_message":{' \
                         '"user_uuid":"baadf00d-baad-baad-baad-baadbaadf00d",' \
                         '"correlation_id":"cafef00d-cafe-cafe-cafe-cafef00dcafe",' \
                         '"uuid":"deadbeef-dead-dead-dead-deaddeafbeef",' \
                         '"context":{},"data":{"param":"42"}}}'

      expect(stored_message.encoded_message).to eq(expected_encoded)

      expect(stored_message.correlation_id).to \
        eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID)

      expect(stored_message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
      expect(stored_message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID)
      expect(stored_message.message_type).to eq('RailwayIpc::Messages::TestMessage')
      expect(stored_message.status).to eq('sent')
      expect(stored_message.exchange).to eq('test:events')
      expect(stored_message.inserted_at.utc).to be_within(1.second).of(Time.current)
    }.to change{ RailwayIpc::PublishedMessage.count }.by(1)
  end
end
