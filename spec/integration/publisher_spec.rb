require_relative "./i_spec.rb"

RSpec.describe "Publishing a message" do
  let(:publisher) { RailwayIpc::TestPublisher.instance }
  let(:message)   { LearnIpc::Commands::TestMessage.new }
  let(:encoded_message) { Base64.encode64(LearnIpc::Commands::TestMessage.encode(message)) }

  xit "persists the requested document" do
    user_uuid =  SecureRandom.uuid
    correlation_id =  SecureRandom.uuid
    uuid =  SecureRandom.uuid
    message.user_uuid = user_uuid
    message.correlation_id = correlation_id
    message.uuid = uuid
    publisher.publish(message)
    stored_message = RailwayIpc::PublishedMessage.find(uuid)
    expect(stored_message.uuid).to eq(uuid)
    expect(stored_message.user_uuid).to eq(user_uuid)
    expect(stored_message.correlation_id).to eq(correlation_id)
    expect(stored_message.message_type).to eq("LearnIpc::Commands::TestMessage")
    expect(stored_message.status).to eq("sent")
    expect(stored_message.exchange).to eq("test:events")
  end
end