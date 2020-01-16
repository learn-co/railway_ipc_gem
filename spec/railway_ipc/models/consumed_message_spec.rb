require 'rails_helper'

RSpec.describe RailwayIpc::ConsumedMessage, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:uuid) }
    it { should validate_presence_of(:status) }
    it do
      should validate_inclusion_of(:status)
        .in_array(RailwayIpc::ConsumedMessage::STATUSES.values)
    end
  end

  describe '#processed?' do
    context 'when status is "success"' do
      it 'returns true' do
        msg = create(:consumed_message, status: RailwayIpc::ConsumedMessage::STATUSES[:success])

        expect(msg.processed?).to eq(true)
      end
    end

    context 'when status is anything but "success"' do
      it 'returns false' do
        msg = create(:consumed_message, status: 'processing')
        expect(msg.processed?).to eq(false)
      end
    end
  end

  describe 'initial save to DB' do
    it 'saves an inserted_at date for the current time' do
      msg = create(:consumed_message, status: RailwayIpc::ConsumedMessage::STATUSES[:success])
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
