RSpec.describe RailwayIpc::Consumer do
  describe ".listen_to" do
    it "specifies the queue and exchange" do
      expect(RailwayIpc::TestConsumer).to receive(:from_queue).with("test_queue", {
          exchange: "test_exchange",
          durable: true,
          exchange_type: :fanout,
          connection: RailwayIpc.bunny_connection
      })
      RailwayIpc::TestConsumer.listen_to(queue: "test_queue", exchange: "test_exchange")
    end
  end

  it "registers the handler for the message" do
    RailwayIpc::Consumer.handle(LearnIpc::Commands::TestMessage, with: RailwayIpc::TestHandler)
    expect(RailwayIpc::ConsumerResponseHandlers.instance.registered)
        .to include("LearnIpc::Commands::TestMessage")
  end

  describe '#work_with_params' do
    let(:consumer) { RailwayIpc::TestConsumer.new }
    context "consumer does not have a handler for the message" do
      let(:payload) { RailwayIpc::Rabbitmq::Payload.encode(LearnIpc::Commands::UnhandledMessage.new) }
      let(:null_handler) { RailwayIpc::NullHandler.new }

      it "routes the message to the correct handler" do
        allow(RailwayIpc::NullHandler).to receive(:new).and_return(null_handler)
        expect(null_handler).to receive(:handle).with(instance_of(RailwayIpc::BaseMessage))

        consumer.work_with_params(payload, nil, nil)
      end

      it "acks the message" do
        allow(RailwayIpc::NullHandler).to receive(:new).and_return(null_handler)
        expect(null_handler).to receive(:ack!)

        consumer.work_with_params(payload, nil, nil)
      end
    end

    context 'when message is successfully decoded with known message type' do
      context 'when a consumed message records alreadys exists' do
        context 'when message has a status of "success"' do
          let!(:test_message) { test_message_stub }
          let!(:payload) { payload_stub(test_message) }
          let!(:delivery_info) { delivery_info_stub }
          let!(:consumed_message) { consumed_message_stub(message: test_message) }
          let!(:test_handler) { RailwayIpc::TestHandler.new }

          it 'does not update the consumed message record' do
            expect {
              consumer.work_with_params(payload, delivery_info, nil)
            }.to_not change { consumed_message.updated_at }
          end

          it 'does not process the message' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            expect(test_handler).not_to receive(:handle)

            consumer.work_with_params(payload, delivery_info, nil)
          end

          it 'acks the message' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            expect(test_handler).to receive(:ack!)

            consumer.work_with_params(payload, delivery_info, nil)
          end
        end
      end
    end
  end

  private

  def payload_stub(message = create(:test_message))
    {
      type: message.class.to_s,
      encoded_message: Base64.encode64(
        LearnIpc::Commands::TestMessage.encode(message)
      )
    }.to_json
  end

  def test_message_stub
    LearnIpc::Commands::TestMessage.new(
      uuid: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      user_uuid: SecureRandom.uuid,
      data: LearnIpc::Commands::TestMessage::Data.new(iteration: "bk-001")
    )
  end

  def delivery_info_stub
    OpenStruct.new(
      exchange: 'ipc:location:events',
      consumer: OpenStruct.new(
        queue: OpenStruct.new(
          name: 'source:location:events'
        )
      )
    )
  end

  def consumed_message_stub(message: test_message_stub, status: RailwayIpc::ConsumedMessage::SUCCESS_STATUS)
    create(
      :consumed_message,
      user_uuid: message.user_uuid,
      correlation_id: message.correlation_id,
      uuid: message.uuid,
      updated_at: 5.minutes.ago,
      status: status
    )
  end
end
