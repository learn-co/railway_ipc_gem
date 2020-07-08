# frozen_string_literal: true

RSpec.describe RailwayIpc::Handler do
  let(:handler) { RailwayIpc::TestHandler.new }
  let(:message) { RailwayIpc::Messages::TestMessage.new }

  context "when the message is handled successfully" do
    it "logs the message was successful" do
      expect(RailwayIpc.logger).to receive(:info).with(message, "Handling message")
      expect(RailwayIpc.logger).to receive(:info).with(message, "Successfully handled message")
      handler.handle(message)
    end
  end

  context "when the message is not handled successfully" do
    before do
      response = double('response', {success?: false})
      block = double('block', call: response)
      allow(RailwayIpc::TestHandler).to receive(:block).and_return(block)
    end

    it "logs the message failed" do
      expect(RailwayIpc.logger).to receive(:info).with(message, "Handling message")
      expect(RailwayIpc.logger).to receive(:error).with(message, "Failed to handle message")
      handler.handle(message)
    end
  end
end
