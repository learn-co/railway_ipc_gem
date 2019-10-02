RSpec.describe RailwayIpc::Handler do
  let(:handler) { RailwayIpc::TestHandler.new }
  let(:message) { LearnIpc::Commands::TestMessage.new }

  context "when the message is handled successfully" do
    it "acks the message" do
      expect(handler).to receive(:ack!)
      handler.handle(message)
    end
  end

  context "when the message is not handled successfully" do
    before do
      response = double('response', {success?: false})
      block = double('block', call: response)
      allow(RailwayIpc::TestHandler).to receive(:block).and_return(block)
    end

    it "acks the message" do
      expect(handler).to receive(:ack!)
      handler.handle(message)
    end
  end
end
