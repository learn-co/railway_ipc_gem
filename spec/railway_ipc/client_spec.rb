RSpec.describe RailwayIpc::Client do
  let(:rabbit_adapter) do
    double = class_double(RailwayIpc::Rabbitmq::Adapter)
    expect(double)
        .to receive(:new)
        .with({:exchange_name => "ipc:test:requests", :options => {:automatic_recovery => false}})
        .and_return(adapter_instance)
    double
  end

  let(:adapter_instance) do
    instance_double(RailwayIpc::Rabbitmq::Adapter, queue: double("queue", name: "My queue"))
  end

  before do
    @client = RailwayIpc::TestClient.new(rabbit_adapter: rabbit_adapter)
  end
  describe '#request' do
    context 'when the client does not know how to handle the message' do
      let(:message) { LearnIpc::Requests::UnhandledRequest.new(user_uuid: '1234', correlation_id: '1234') }
      before do
        @payload = message
      end
      it 'raises an error' do
        expect { @client.request(@payload) }.to raise_error(RailwayIpc::UnhandledMessageError)
      end
    end
    context 'when the server knows how to handle the message' do
      let(:message) { LearnIpc::Documents::TestDocument.new(user_uuid: '1234', correlation_id: '1234') }
      before do
        @payload = message
      end
      it 'sets up connection correctly' do
        mutated_payload = @payload.clone
        mutated_payload.reply_to = "My queue"
        expect(adapter_instance).to receive(:connect).and_return(adapter_instance)
        expect(adapter_instance).to receive(:create_exchange).and_return(adapter_instance)
        expect(adapter_instance).to receive(:create_queue).and_return(adapter_instance)
        expect(adapter_instance).to receive(:publish).with(RailwayIpc::Rabbitmq::Payload.encode(mutated_payload), routing_key: "")
        expect(adapter_instance).to receive(:check_for_message).with(timeout: 10)
        @client.request(@payload)
        expect(response).to be_a(LearnIpc::Documents::TestDocument)
      end
      it 'processes response payload' do

      end
    end
  end
end
