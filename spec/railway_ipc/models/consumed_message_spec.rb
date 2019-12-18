require 'rails_helper'

RSpec.describe RailwayIpc::ConsumedMessage do
  describe 'initial save to DB' do
    it 'saves an inserted_at date for the current time' do
      msg = RailwayIpc::ConsumedMessage.create({
                                                   uuid: SecureRandom.uuid,
                                                   message_type: 'LearnIpc::Commands::TestMessage',
                                                   encoded_message: '',
                                                   status: 'success'
                                               })

      expect(msg.inserted_at.utc).to be_within(1.second).of(Time.current)
    end
  end

  describe "decoding messages on load" do
    it "decodes message known to the system"
    it "decodes message not known to the system" do
      msg = RailwayIpc::ConsumedMessage.create({
         uuid: SecureRandom.uuid,
         message_type: 'SURPRISE',
         encoded_message: "\n$b5797a84-7ef5-44a7-ac90-0aad7284f0b7\x12$de2c778f-0db5-4cfb-acbf-fc759c967d44\x1A$24b36430-6105-4646-a343-2272078cd90e\"\x1FLearnIpc::Commands::TestMessage",
         status: 'success'
      })
      expect(msg.decoded_message).to be_a(RailwayIpc::BaseMessage)
      expect(msg.decoded_message.uuid).to eq("24b36430-6105-4646-a343-2272078cd90e")
      expect(msg.decoded_message.user_uuid).to eq("b5797a84-7ef5-44a7-ac90-0aad7284f0b7")
      expect(msg.decoded_message.correlation_id).to eq("de2c778f-0db5-4cfb-acbf-fc759c967d44")
      expect(msg.decoded_message.type).to eq("LearnIpc::Commands::TestMessage")
    end
  end
end
