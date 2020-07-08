# frozen_string_literal: true

RSpec.describe RailwayIpc::Client do
  let(:rabbit_adapter) do
    double = class_double(RailwayIpc::Rabbitmq::Adapter)
    expect(double)
        .to receive(:new)
                .with({ :exchange_name => 'ipc:test:requests', :options => { :automatic_recovery => false } })
                .and_return(adapter_instance)
    double
  end

  let(:adapter_instance) do
    instance_double(RailwayIpc::Rabbitmq::Adapter, queue: double('queue', name: 'My queue'))
  end
  describe '#request' do
    context 'completing the request out to the server' do
      let(:message) { LearnIpc::Requests::TestRequest.new(user_uuid: '1234', correlation_id: '1234') }
      it 'sets up connection correctly' do
        client = RailwayIpc::TestClient.new(message, rabbit_adapter: rabbit_adapter)
        mutated_payload = message.clone
        mutated_payload.reply_to = adapter_instance.queue.name
        expect(adapter_instance).to receive(:connect).and_return(adapter_instance)
        expect(adapter_instance).to receive(:create_exchange).and_return(adapter_instance)
        expect(adapter_instance).to receive(:create_queue).and_return(adapter_instance)
        expect(adapter_instance).to receive(:publish).with(RailwayIpc::Rabbitmq::Payload.encode(mutated_payload), routing_key: '')
        expect(adapter_instance).to receive(:check_for_message).with(timeout: 10)
        expect(adapter_instance).to receive(:disconnect)
        client.request
      end
    end
  end

  describe 'handling server response' do
    context 'server sends garbage' do
      let(:message) { LearnIpc::Requests::UnhandledRequest.new(user_uuid: '1234', correlation_id: '1234') }
      it 'returns correct response object' do
        payload = RailwayIpc::Rabbitmq::Payload.encode(message)
        allow(adapter_instance).to receive(:connect).and_return(adapter_instance)
        allow(adapter_instance).to receive(:create_exchange).and_return(adapter_instance)
        allow(adapter_instance).to receive(:create_queue).and_return(adapter_instance)
        allow(adapter_instance).to receive(:check_for_message).and_yield(nil, nil, payload)
        allow(adapter_instance).to receive(:disconnect).and_return(adapter_instance)
        client = RailwayIpc::TestClient.new(nil, rabbit_adapter: rabbit_adapter)
        client.setup_rabbit_connection
        response = client.await_response(10)
        expect(response.success).to be_falsey
        expect(response.body.class).to eq(LearnIpc::ErrorMessage)
      end
    end
  end
end
