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
                arguments: {
                  'x-dead-letter-exchange' => 'ipc:errors'
                },
                connection: RailwayIpc.bunny_connection
              })

      expect(RailwayIpc.logger).to_not receive(:info)

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
                connection: RailwayIpc.bunny_connection,
                threads: 1,
                prefetch: 2,
                arguments: {
                  'x-dead-letter-exchange' => 'custom_dlx'
                }
              })

      expect(RailwayIpc.logger)
        .to receive(:info).with(
          'Overriding configuration for test_queue with new options',
          feature: 'railway_ipc_consumer',
          options: {
            durable: false,
            prefetch: 2,
            threads: 1,
            arguments: {
              'x-dead-letter-exchange' => 'custom_dlx'
            }
          }
        )

      RailwayIpc::TestConsumer.listen_to(
        queue: 'test_queue',
        exchange: 'test_exchange',
        options: {
          durable: false,
          threads: 1,
          prefetch: 2,
          arguments: {
            'x-dead-letter-exchange' => 'custom_dlx'
          }
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

RSpec.describe RailwayIpc::Consumer, '#work_with_params' do
  let(:delivery_info) { instance_double(Bunny::DeliveryInfo) }
  let(:metadata) { instance_double(Bunny::MessageProperties, headers: {}) }

  it 'processes the message' do
    consumer = RailwayIpc::TestConsumer.new
    expect {
      consumer.work_with_params(stubbed_pb_binary_payload, delivery_info, metadata)
    }.to change { RailwayIpc::ConsumedMessage.count }.by(1)
  end

  it 'acknowledges the message' do
    consumer = RailwayIpc::TestConsumer.new
    result = \
      consumer.work_with_params(stubbed_pb_binary_payload, delivery_info, metadata)

    expect(result).to eq(:ack)
  end

  context 'when an error occurs' do
    let(:consumer) { RailwayIpc::TestConsumer.new }

    before(:each) do
      allow(RailwayIpc::ProcessIncomingMessage).to \
        receive(:call).and_raise(StandardError)
    end

    it 'logs any errors' do
      expect(RailwayIpc.logger).to \
        receive(:error).with(
          'StandardError',
          {
            feature: 'railway_ipc_consumer',
            error: StandardError,
            exchange: 'test:events',
            queue: 'ironboard:test:commands',
            payload: stubbed_pb_binary_payload
          }
        )

      consumer.work_with_params(stubbed_pb_binary_payload, delivery_info, metadata)
    end

    it 'rejects the message' do
      result = \
        consumer.work_with_params(stubbed_pb_binary_payload, delivery_info, metadata)

      expect(result).to eq(:reject)
    end
  end
end
