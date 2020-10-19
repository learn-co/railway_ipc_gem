# frozen_string_literal: true

RSpec.describe RailwayIpc::Consumer, '.listen_to' do
  context 'default options' do
    it 'specifies the queue and exchange' do
      expect(RailwayIpc::TestConsumer)
        .to receive(:from_queue)
        .with('test_queue', {
                exchange: 'test_exchange',
                durable: true,
                exchange_type: :fanout,
                connection: RailwayIpc.bunny_connection
              })

      RailwayIpc::TestConsumer.listen_to(queue: 'test_queue', exchange: 'test_exchange')
    end
  end

  context 'custom options' do
    it 'merges additional options for .from_queue' do
      expect(RailwayIpc::TestConsumer)
        .to receive(:from_queue)
        .with('test_queue', {
                exchange: 'test_exchange',
                durable: false,
                exchange_type: :fanout,
                connection: RailwayIpc.bunny_connection
              })

      RailwayIpc::TestConsumer.listen_to(
        queue: 'test_queue',
        exchange: 'test_exchange',
        options: {
          durable: false
        }
      )
    end
  end
end

RSpec.describe RailwayIpc::Consumer, '.handle' do
  it 'registers the handler for the message' do
    consumer = RailwayIpc::TestConsumer.new
    expect(consumer.get_handler('RailwayIpc::Messages::TestMessage')).to \
      be_an_instance_of(RailwayIpc::TestHandler)
    second_consumer = RailwayIpc::SecondTestConsumer.new
    expect(second_consumer.get_handler('RailwayIpc::Messages::TestMessage')).to \
      be_an_instance_of(RailwayIpc::SecondTestHandler)
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
    let(:consumer) { RailwayIpc::TestConsumer.new }

    it 're-raises and logs any errors' do
      allow(RailwayIpc::ProcessIncomingMessage).to \
        receive(:call).and_raise(StandardError)

      expect(RailwayIpc.logger).to \
        receive(:error).with(
          'StandardError',
          {
            feature: 'railway_ipc_consumer',
            error: StandardError,
            exchange: 'test:events',
            queue: 'ironboard:test:commands',
            payload: stubbed_payload
          }
        )

      expect {
        consumer.work(stubbed_payload)
      }.to raise_error(StandardError)
    end
  end
end
