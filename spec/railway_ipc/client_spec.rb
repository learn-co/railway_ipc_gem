RSpec.describe RailwayIpc::Client do
  let(:queue)      { double('queue', {bind: true})}
  let(:exchange)   { double('exchange') }
  let(:channel)    { double('channel', {exchange_declare: exchange, register_exchange: true, queue: queue}) }
  let(:connection) { double('connection', {start: true, create_channel: channel}) }

  before do
    allow(RailwayIpc::Rabbitmq::Connection).to receive(:create_bunny_connection).and_return(connection)
    @client = RailwayIpc::TestClient.new
  end
  describe "#work" do
    context "when the client does not know how to handle the message" do
      let(:message)   { LearnIpc::Requests::UnhandledRequest.new(user_uuid: "1234", correlation_id: "1234") }
      before do
        @payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      end
      it "raises an error" do
        expect{@client.work(@payload)}.to raise_error(RailwayIpc::UnhandledMessageError)
      end
    end
    context "when the server does know how to handle the message" do
      let(:message)   { LearnIpc::Documents::TestDocument.new(user_uuid: "1234", correlation_id: "1234") }
      before do
        @payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      end
      it "responds to the message" do
        response = @client.work(@payload)
        expect(response).to be_a(LearnIpc::Documents::TestDocument)
      end
    end
  end
end
