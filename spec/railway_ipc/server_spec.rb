# frozen_string_literal: true

RSpec.describe RailwayIpc::Server do
  describe "#work" do
    let(:exchange)   { double('exchange') }
    let(:channel)    { double('channel', {default_exchange: exchange}) }
    let(:connection) { double('connection', {start: true, create_channel: channel}) }

    before do
      @server = RailwayIpc::TestServer.new
    end
    context "when the server does not know how to handle the message" do
      let(:message)   { LearnIpc::Requests::UnhandledRequest.new(user_uuid: "1234", correlation_id: "1234", reply_to: "queue_name") }
      before do
        @payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      end
      it "raises an error" do
        expect{@server.work(@payload)}.to raise_error(RailwayIpc::UnhandledMessageError)
      end
    end

    context "when the server does know how to handle the message" do
      let(:message)   { LearnIpc::Requests::TestRequest.new(user_uuid: "1234", correlation_id: "1234", reply_to: "queue_name") }
      before do
        @payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      end
      it "responds to the message" do
        response = @server.work(@payload)
        expect(response).to be_a(LearnIpc::Documents::TestDocument)
      end
    end
  end
end
