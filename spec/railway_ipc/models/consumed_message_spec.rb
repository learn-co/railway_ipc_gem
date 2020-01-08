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

  describe "#decoded_message" do
    describe "when message type is know to the system" do
      it "decodes message using the defined message type" do
        test_msg_data = test_msg_data_stub
        decoded_message = RailwayIpc::ConsumedMessage.create!({
          uuid: SecureRandom.uuid,
          message_type: 'LearnIpc::Commands::TestMessage',
          encoded_protobuf: test_msg_data.encoded_protobuf,
          status: 'success'
        }).decoded_message

        expect(decoded_message).to be_a(LearnIpc::Commands::TestMessage)
        expect(decoded_message.uuid).to eq(test_msg_data.uuid)
        expect(decoded_message.user_uuid).to eq(test_msg_data.user_uuid)
        expect(decoded_message.correlation_id).to eq(test_msg_data.correlation_id)
      end
    end

    describe "when message type is not known to the system" do
      it "decodes message as RailwayIpc::BaseMessage" do
        test_msg_data = test_msg_data_stub
        decoded_message = RailwayIpc::ConsumedMessage.create!({
          uuid: SecureRandom.uuid,
          message_type: 'SURPRISE',
          encoded_protobuf: test_msg_data.encoded_protobuf,
          status: 'success'
        }).decoded_message

        expect(decoded_message).to be_a(RailwayIpc::BaseMessage)
        expect(decoded_message.uuid).to eq(test_msg_data.uuid)
        expect(decoded_message.user_uuid).to eq(test_msg_data.user_uuid)
        expect(decoded_message.correlation_id).to eq(test_msg_data.correlation_id)
      end
    end

    describe "when data field has value in encoded protobuf" do
      it "decodes message" do
        # Message => <LearnIpc::Commands::TestMessage: user_uuid: "b5797a84-7ef5-44a7-ac90-0aad7284f0b7", correlation_id: "de2c778f-0db5-4cfb-acbf-fc759c967d44", uuid: "24b36430-6105-4646-a343-2272078cd90e", context: {}, data: <LearnIpc::Commands::TestMessage::Data: iteration: "test">>
        # Encoded Protobuf => LearnIpc::Commands::TestMessage.encode(Message)
        encoded_protobuf_with_data =
          "\n$b5797a84-7ef5-44a7-ac90-0aad7284f0b7\x12$de2c778f-0db5-4cfb-acbf-fc759c967d44\x1A$24b36430-6105-4646-a343-2272078cd90e*\x06\n\x04test"
        test_msg_data = test_msg_data_stub(encoded_protobuf: encoded_protobuf_with_data)
        decoded_message = RailwayIpc::ConsumedMessage.create!({
          uuid: SecureRandom.uuid,
          message_type: 'LearnIpc::Commands::TestMessage',
          encoded_protobuf: test_msg_data.encoded_protobuf,
          status: 'success'
        }).decoded_message

        expect(decoded_message).to be_a(LearnIpc::Commands::TestMessage)
        expect(decoded_message.uuid).to eq(test_msg_data.uuid)
        expect(decoded_message.user_uuid).to eq(test_msg_data.user_uuid)
        expect(decoded_message.correlation_id).to eq(test_msg_data.correlation_id)
      end
    end

    describe "when data field is nil in encoded protobuf" do
      it "decodes message" do
        # Message => <LearnIpc::Commands::TestMessage: user_uuid: "b5797a84-7ef5-44a7-ac90-0aad7284f0b7", correlation_id: "de2c778f-0db5-4cfb-acbf-fc759c967d44", uuid: "24b36430-6105-4646-a343-2272078cd90e", context: {}, data: nil>
        # Encoded Protobuf => LearnIpc::Commands::TestMessage.encode(Message) =>
        encoded_protobuf_without_data =
          "\n$b5797a84-7ef5-44a7-ac90-0aad7284f0b7\x12$de2c778f-0db5-4cfb-acbf-fc759c967d44\x1A$24b36430-6105-4646-a343-2272078cd90e"
        test_msg_data = test_msg_data_stub(encoded_protobuf: encoded_protobuf_without_data)
        decoded_message = RailwayIpc::ConsumedMessage.create!({
          uuid: SecureRandom.uuid,
          message_type: 'LearnIpc::Commands::TestMessage',
          encoded_protobuf: test_msg_data.encoded_protobuf,
          status: 'success'
        }).decoded_message

        expect(decoded_message).to be_a(LearnIpc::Commands::TestMessage)
        expect(decoded_message.uuid).to eq(test_msg_data.uuid)
        expect(decoded_message.user_uuid).to eq(test_msg_data.user_uuid)
        expect(decoded_message.correlation_id).to eq(test_msg_data.correlation_id)
      end
    end

    describe '#persist' do
      let(:user_uuid) { SecureRandom.uuid }
      let(:correlation_id) { SecureRandom.uuid }
      let(:uuid) { SecureRandom.uuid }
      let(:message) do
        LearnIpc::Commands::TestMessage.new(
            uuid: uuid,
            user_uuid: user_uuid,
            correlation_id: correlation_id,
            data: LearnIpc::Commands::TestMessage::Data.new(
                iteration: "bk-001"
            )
        )
      end
      let(:consumer) { RailwayIpc::TestConsumer.new }
      let(:encoded_message) { LearnIpc::Commands::TestMessage.encode(message) }
      let(:payload) do
        {
          type: message.class.to_s,
          encoded_message: Base64.encode64(encoded_message)
        }.to_json
      end
      let(:test_handler) { RailwayIpc::TestHandler.new }

      describe 'when message is successfully decoded with known message type' do
        describe 'when consumed message record with matching UUID exits' do
          describe 'when message has a status of "ignore" or "success"' do
            # handler.handle(msg) -> { success?: Bool }
            it 'does not update the consumed message record'
            it 'does not process the message'
            it 'acks the message'
          end

          describe 'when message has status of "processing" or "unknown_message_type"' do
            it 'adds a persistance db lock to the consumed message record, processes it, and updates the message with a status of "success"'
            it 'acks the message'
          end
        end

        describe 'when consumed message record with matching UUID does not exits' do
          describe 'when persistance is successful' do
            it 'created the record with a status of "processing", added a persistance db lock to the record while processing the the message and updated the message status to "success" after being handled'
          end

          describe 'when persistance fails' do
            it 'logs an errors'
            it 'acks the message'
          end
        end
      end

      describe 'when message is not successfully decoded with unknown message type' do
        describe 'when persistance is successful' do
          it 'creates the record with a status of "unknown_message_type"'
          it 'does not process the message'
          it 'acks the message'
        end

        describe 'when persistance fails' do
          it 'logs and error'
          it 'acks the message'
        end
      end
    end
  end

  private

  def test_msg_data_stub(encoded_protobuf: nil)
    default_encoded_protobuf = "\n$b5797a84-7ef5-44a7-ac90-0aad7284f0b7\x12$de2c778f-0db5-4cfb-acbf-fc759c967d44\x1A$24b36430-6105-4646-a343-2272078cd90e*\x00"

    OpenStruct.new(
      uuid: "24b36430-6105-4646-a343-2272078cd90e",
      user_uuid: "b5797a84-7ef5-44a7-ac90-0aad7284f0b7",
      correlation_id: "de2c778f-0db5-4cfb-acbf-fc759c967d44",
      encoded_protobuf: encoded_protobuf || default_encoded_protobuf
    )
  end
end
