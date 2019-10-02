RSpec.describe RailwayIpc::Rabbitmq::Payload do
  let(:message)   { LearnIpc::Commands::TestMessage.new(user_uuid: "1234") }

  describe ".encode" do
    it "encodes the message" do
      payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      expect(payload).to eq("{\"type\":\"LearnIpc::Commands::TestMessage\",\"encoded_message\":\"CgQxMjM0\\n\"}")
    end
  end

  describe ".decode" do
    it "decodes the message" do
      payload = RailwayIpc::Rabbitmq::Payload.encode(message)
      decoded = RailwayIpc::Rabbitmq::Payload.decode(payload)
      expect(decoded.type).to eq("LearnIpc::Commands::TestMessage")
      expect(decoded.message).to eq("\n\x041234")
    end
  end
end
