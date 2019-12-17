RSpec.describe RailwayIpc::Publisher do
  let(:publisher) { RailwayIpc::TestPublisher.instance }
  let(:message)   { LearnIpc::Commands::TestMessage.new }
  let(:encoded_message) { Base64.encode64(LearnIpc::Commands::TestMessage.encode(message)) }

  it "knows its exchange" do
    expect(publisher.class.exchange_name).to eq("test:events")
  end

  it "initializes the Sneakers publisher with the correct exchange and exchange type" do
    expect(publisher.instance_variable_get(:@opts)[:exchange]).to eq("test:events")
    expect(publisher.instance_variable_get(:@opts)[:exchange_options][:type]).to eq(:fanout)
  end
end
