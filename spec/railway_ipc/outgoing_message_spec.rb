# frozen_string_literal: true

RSpec.describe RailwayIpc::OutgoingMessage, 'initialization' do
  let(:proto) { stubbed_protobuf }
  subject { described_class.new(proto, 'test:events') }

  it { expect(subject.proto).to eq(proto) }
  it { expect(subject.exchange).to eq('test:events') }
end

RSpec.describe RailwayIpc::OutgoingMessage, 'delegated methods' do
  subject { described_class.new(stubbed_protobuf, 'test:events') }

  it { expect(subject.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID) }
end

RSpec.describe RailwayIpc::OutgoingMessage, '#uuid' do
  it 'uses the given UUID' do
    subject = described_class.new(stubbed_protobuf, 'test:events')
    expect(subject.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
  end

  it "assigns a UUID if one isn't given" do
    subject = described_class.new(RailwayIpc::Messages::TestMessage.new, 'test:events')
    expect(subject.uuid.blank?).to eq(false)
  end
end

RSpec.describe RailwayIpc::OutgoingMessage, '#correlation_id' do
  it 'uses the given correlation_id' do
    subject = described_class.new(stubbed_protobuf, 'test:events')
    expect(subject.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID)
  end

  it "assigns a correlation_id if one isn't given" do
    subject = described_class.new(RailwayIpc::Messages::TestMessage.new, 'test:events')
    expect(subject.correlation_id.blank?).to eq(false)
  end
end

RSpec.describe RailwayIpc::OutgoingMessage, '#type' do
  subject { described_class.new(stubbed_protobuf, 'test:events') }

  it { expect(subject.type).to eq('RailwayIpc::Messages::TestMessage') }
end

RSpec.describe RailwayIpc::OutgoingMessage, '#encoded' do
  it 'encodes a message in binary protobuf format' do
    subject = described_class.new(stubbed_protobuf, 'test:events')

    expected = '{"type":"RailwayIpc::Messages::TestMessage",' \
               '"encoded_message":"CiRiYWFkZjAwZC1iYWFkLWJhYWQtYmFhZC1i' \
               'YWFkYmFhZGYwMGQSJGNhZmVm\\nMDBkLWNhZmUtY2FmZS1jYWZlLWNh' \
               'ZmVmMDBkY2FmZRokZGVhZGJlZWYtZGVh\\nZC1kZWFkLWRlYWQtZGVh' \
               'ZGRlYWZiZWVmIg0KBHNvbWUSBXZhbHVlKgQKAjQy\\n"}'

    expect(subject.encoded).to eq(expected)
  end

  it 'encodes a message in json protobuf format' do
    subject = described_class.new(stubbed_protobuf, 'test:events', 'json_protobuf')

    expected = '{"type":"RailwayIpc::Messages::TestMessage",' \
               '"encoded_message":{' \
               '"user_uuid":"baadf00d-baad-baad-baad-baadbaadf00d",' \
               '"correlation_id":"cafef00d-cafe-cafe-cafe-cafef00dcafe",' \
               '"uuid":"deadbeef-dead-dead-dead-deaddeafbeef",' \
               '"context":{"some":"value"},"data":{"param":"42"}}}'

    expect(subject.encoded).to eq(expected)
  end
end
