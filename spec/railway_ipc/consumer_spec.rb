RSpec.describe RailwayIpc::Consumer do
  let(:user_uuid) { SecureRandom.uuid }
  let(:correlation_id) { SecureRandom.uuid }
  let(:uuid) { SecureRandom.uuid }
  let(:message) do
    LearnIpc::Commands::TestMessage.new(
        uuid: uuid,
        user_uuid: user_uuid,
        correlation_id: correlation_id,
        type: "LearnIpc::Commands::TestMessage",
        data: LearnIpc::Commands::TestMessage::Data.new(
            iteration: "bk-001"
        )
    )
  end

  let(:consumer) { RailwayIpc::TestConsumer.new }
  let(:encoded_message) { LearnIpc::Commands::TestMessage.encode(message) }

  let(:payload) do
    {
        type: message.class.to_s,
        encoded_message: Base64.encode64(encoded_message)
    }.to_json
  end
  let(:handler_instance) { RailwayIpc::TestHandler.new }

  describe ".listen_to" do
    it "specifies the queue and exchange" do
      expect(RailwayIpc::TestConsumer).to receive(:from_queue).with("test_queue", {
          exchange: "test_exchange",
          durable: true,
          exchange_type: :fanout,
          connection: RailwayIpc.bunny_connection
      })
      RailwayIpc::TestConsumer.listen_to(queue: "test_queue", exchange: "test_exchange")
    end
  end


  it "registers the handler for the message" do
    RailwayIpc::Consumer.handle(LearnIpc::Commands::TestMessage, with: RailwayIpc::TestHandler)
    expect(RailwayIpc::ConsumerResponseHandlers.instance.registered)
        .to include("LearnIpc::Commands::TestMessage")
  end

  it "routes the message to the correct handler" do
    allow(RailwayIpc::TestHandler).to receive(:new).and_return(handler_instance)
    expect(handler_instance).to receive(:handle).with(instance_of(LearnIpc::Commands::TestMessage))
    consumer.work(payload)
  end

  it "acks the message" do
    allow(RailwayIpc::TestHandler).to receive(:new).and_return(handler_instance)
    expect(handler_instance).to receive(:ack!)
    consumer.work(payload)
  end

  context "consumer does not have a handler for the message" do
    let(:message) { LearnIpc::Commands::UnhandledMessage.new }
    let(:payload) { RailwayIpc::Rabbitmq::Payload.encode(message) }

    let(:handler_instance) { RailwayIpc::NullHandler.new }
    it "routes the message to the correct handler" do
      allow(RailwayIpc::NullHandler).to receive(:new).and_return(handler_instance)
      expect(handler_instance).to receive(:handle).with(instance_of(RailwayIpc::NullMessage))
      consumer.work(payload)
    end

    it "acks the message" do
      allow(RailwayIpc::NullHandler).to receive(:new).and_return(handler_instance)
      expect(handler_instance).to receive(:ack!)
      consumer.work(payload)
    end
  end
end
