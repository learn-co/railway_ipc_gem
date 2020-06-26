RSpec.describe RailwayIpc::Publisher do
  let(:publisher) { RailwayIpc::TestPublisher.instance }
  let(:message)   { LearnIpc::Commands::TestMessage.new(
    uuid: SecureRandom.uuid,
    correlation_id: SecureRandom.uuid
  ) }
  let(:encoded_message) { Base64.encode64(LearnIpc::Commands::TestMessage.encode(message)) }

  it "knows its exchange" do
    expect(publisher.class.exchange_name).to eq("test:events")
  end

  it "initializes the Sneakers publisher with the correct exchange and exchange type" do
    expect(publisher.instance_variable_get(:@opts)[:exchange]).to eq("test:events")
    expect(publisher.instance_variable_get(:@opts)[:exchange_options][:type]).to eq(:fanout)
  end

  it "auto generates a message uuid if one is not passed in" do
    message.uuid = ""
    uuid = SecureRandom.uuid

    message_with_uuid = message.clone
    message_with_uuid.uuid = uuid

    allow(SecureRandom).to receive(:uuid).and_return(uuid)
    allow_any_instance_of(Sneakers::Publisher).to receive(:publish).with(anything())
    expect(RailwayIpc::Rabbitmq::Payload).to receive(:encode).at_least(1).times.with(message_with_uuid).and_call_original
    publisher.publish(message)
  end

  it "auto generates a correlation_id if one is not passed in" do
    message.correlation_id = ""
    correlation_id = SecureRandom.uuid

    message_with_correlation_id = message.clone
    message_with_correlation_id.correlation_id = correlation_id

    allow(SecureRandom).to receive(:uuid).and_return(correlation_id)
    allow_any_instance_of(Sneakers::Publisher).to receive(:publish).with(anything())
    expect(RailwayIpc::Rabbitmq::Payload).to receive(:encode).at_least(1).times.with(message_with_correlation_id).and_call_original
    publisher.publish(message)
  end
end
