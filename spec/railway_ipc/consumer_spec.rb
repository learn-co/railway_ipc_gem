RSpec.describe RailwayIpc::Consumer, '.listen_to' do
  it "specifies the queue and exchange" do
    expect(RailwayIpc::TestConsumer).to receive(:from_queue).with('test_queue', {
      exchange: 'test_exchange',
      durable: true,
      exchange_type: :fanout,
      connection: RailwayIpc.bunny_connection
    })
    RailwayIpc::TestConsumer.listen_to(queue: "test_queue", exchange: "test_exchange")
  end

end

RSpec.describe RailwayIpc::Consumer, '.handle' do
  it "registers the handler for the message" do
    RailwayIpc::Consumer.handle(RailwayIpc::Messages::TestMessage, with: RailwayIpc::TestHandler)
    expect(RailwayIpc::ConsumerResponseHandlers.instance.registered).to \
      include('RailwayIpc::Messages::TestMessage')
  end
end

RSpec.describe RailwayIpc::Consumer, '#work' do
  it 'processes the message' do
    consumer = RailwayIpc::TestConsumer.new
    expect {
      consumer.work(stubbed_payload)
    }.to change { RailwayIpc::ConsumedMessage.count }.by(1)
  end

  it 'acknowledges the message' do
    consumer = RailwayIpc::TestConsumer.new
    expect(consumer.work(stubbed_payload)).to eq(:ack)
  end

  context 'when an error occurs' do
    let(:fake_logger) { RailwayIpc::SpecHelpers::FakeLogger.new }
    let(:consumer) { RailwayIpc::TestConsumer.new }

    around(:each) do |example|
      original_logger = RailwayIpc.logger.logger
      RailwayIpc.configure(logger: fake_logger)
      example.run
      RailwayIpc.configure(logger: original_logger)
    end

    it 're-raises and logs any errors' do
      allow(RailwayIpc::ProcessIncomingMessage).to \
        receive(:call).and_raise(StandardError)

      expect {
        consumer.work(stubbed_payload)
      }.to raise_error(StandardError)

      error_msg = fake_logger.messages[:error].first
      expect(error_msg[:feature]).to eq('railway_consumer')
      expect(error_msg[:error]).to eq(StandardError)
      expect(error_msg[:error_message]).to eq('StandardError')
      expect(error_msg[:payload]).to eq(stubbed_payload)
    end
  end
end
