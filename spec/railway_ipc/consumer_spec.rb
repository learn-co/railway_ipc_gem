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
    context "consumer does not have a handler for the message" do
      let(:payload) { RailwayIpc::Rabbitmq::Payload.encode(LearnIpc::Commands::UnhandledMessage.new) }
      let(:null_handler) { RailwayIpc::NullHandler.new }

      it "routes the message to the correct handler" do
        allow(RailwayIpc::NullHandler).to receive(:new).and_return(null_handler)
        expect(null_handler).to receive(:handle).with(instance_of(RailwayIpc::BaseMessage))
        RailwayIpc::TestConsumer.new.work_with_params(payload, nil, nil)
      end

      it "acks the message" do
        allow(RailwayIpc::NullHandler).to receive(:new).and_return(null_handler)
        expect(null_handler).to receive(:ack!)
        RailwayIpc::TestConsumer.new.work_with_params(payload, nil, nil)
      end
    end

    context 'when message is successfully decoded with known message type' do
      context 'when consumed message record with matching UUID exits' do
        context 'when message has a status of "success"' do
          it 'does not update the consumed message record' do
            # consumed_message_record = create(
            #   :consumed_message,
            #   user_uuid: user_uuid,
            #   correlation_id: correlation_id,
            #   uuid: uuid,
            #   updated_at: 5.minutes.ago,
            #   status: RailwayIpc::ConsumedMessage::SUCCESS_STATUS
            # )

            # expect {
            #   consumer.work_with_params(payload, delivery_info, nil)
            # }.to_not change { consumed_message_record.updated_at }
          end
          it 'does not process the message'
          it 'acks the message'
        end

        context 'when message has status of "processing" or "unknown_message_type"' do
          it 'adds a persistance db lock to the consumed message record, processes it, and updates the message with a status of "success"'
          it 'acks the message'
        end
      end

      context 'when consumed message record with matching UUID does not exits' do
        context 'when persistance is successful' do
          it 'created the record with a status of "processing", added a persistance db lock to the record while processing the the message and updated the message status to "success" after being handled'
        end

        context 'when persistance fails' do
          it 'logs an errors'
          it 'acks the message'
        end
      end
    end

    context 'when message is not successfully decoded with unknown message type' do
      context 'when persistance is successful' do
        it 'creates the record with a status of "unknown_message_type"'
        it 'does not process the message'
        it 'acks the message'
      end

      context 'when persistance fails' do
        it 'logs and error'
        it 'acks the message'
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

  def deliver_info_stub
    OpenStruct.new(
      exchange: 'ipc:location:events',
      consumer: OpenStruct.new(
        queue: OpenStruct.new(
          name: 'source:location:events'
        )
      )
    )
  end
end
