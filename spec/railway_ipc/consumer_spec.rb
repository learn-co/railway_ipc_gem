RSpec.describe RailwayIpc::Consumer do
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
  let(:handler_instance) { RailwayIpc::TestHandler.new }

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

  it "routes the message to the correct handler" do
    allow(RailwayIpc::TestHandler).to receive(:new).and_return(handler_instance)
    expect(handler_instance).to receive(:handle).with(instance_of(LearnIpc::Commands::TestMessage))
    consumer.work(payload)
  end

  it "acks the message" do
    allow(RailwayIpc::TestHandler).to receive(:new).and_return(handler_instance)
    expect(handler_instance).to receive(:ack!)
    consumer.work(payload)
  end

  context "consumer does not have a handler for the message" do
    let(:message) { LearnIpc::Commands::UnhandledMessage.new }
    let(:payload) { RailwayIpc::Rabbitmq::Payload.encode(message) }

    let(:handler_instance) { RailwayIpc::NullHandler.new }
    it "routes the message to the correct handler" do
      allow(RailwayIpc::NullHandler).to receive(:new).and_return(handler_instance)
      expect(handler_instance).to receive(:handle).with(instance_of(RailwayIpc::NullMessage))
      consumer.work(payload)
    end

    it "acks the message" do
      allow(RailwayIpc::NullHandler).to receive(:new).and_return(handler_instance)
      expect(handler_instance).to receive(:ack!)
      consumer.work(payload)
    end
  end

  describe '#work_with_params' do
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
    let(:delivery_info) do
      OpenStruct.new(
        exchange: 'ipc:location:events',
        consumer: OpenStruct.new(
          queue: OpenStruct.new(
            name: 'source:location:events'
          )
        )
      )
    end

    context 'when message is successfully decoded with known message type' do
      context 'when consumed message record with matching UUID exits' do
        let!(:consumed_message) { create(:consumed_message) }
        context 'when message has a status of "success"' do
          it 'does not update the consumed message record' do
            prework_message = consumed_message.update(status: RailwayIpc::ConsumedMessage::SUCCESS_STATUS)
            prework_message.freeze
            consumer.work_with_params(payload, delivery_info, nil)

            message_from_db = RailwayIpc::ConsumedMessage.find! prework_message.uuid
            expect(message_from_db).to eq prework_message
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
end
