# frozen_string_literal: true

RSpec.describe RailwayIpc::MessageEncoders::ProtobufBinaryEncoder do
  it 'encodes the message' do
    expected = '{"type":"RailwayIpc::Messages::TestMessage",' +
               '"encoded_message":"CiRiYWFkZjAwZC1iYWFkLWJhYWQtYmFhZC1i' +
               'YWFkYmFhZGYwMGQSJGNhZmVm\\nMDBkLWNhZmUtY2FmZS1jYWZlLWNh' +
               'ZmVmMDBkY2FmZRokZGVhZGJlZWYtZGVh\\nZC1kZWFkLWRlYWQtZGVh' +
               'ZGRlYWZiZWVmKgQKAjQy\\n"}'

    message = RailwayIpc::OutgoingMessage.new(stubbed_protobuf, 'test:events')
    expect(described_class.call(message)).to eq(expected)
  end

  it 'raises an exception if it fails to encode message' do
    expect {
      described_class.call('something bogus')
    }.to raise_exception(RailwayIpc::InvalidProtobuf)
  end
end

RSpec.describe RailwayIpc::MessageEncoders::ProtobufJsonEncoder do
  it 'encodes the message' do
    expected = '{"type":"RailwayIpc::Messages::TestMessage",' +
               '"encoded_message":{' +
               '"user_uuid":"baadf00d-baad-baad-baad-baadbaadf00d",' +
               '"correlation_id":"cafef00d-cafe-cafe-cafe-cafef00dcafe",' +
               '"uuid":"deadbeef-dead-dead-dead-deaddeafbeef",' +
               '"context":{},"data":{"param":"42"}}}'

    message = RailwayIpc::OutgoingMessage.new(stubbed_protobuf, 'test:events')
    expect(described_class.call(message)).to eq(expected)
  end

  it 'raises an exception if it fails to encode message' do
    expect {
      described_class.call('something bogus')
    }.to raise_exception(RailwayIpc::InvalidProtobuf)
  end
end
