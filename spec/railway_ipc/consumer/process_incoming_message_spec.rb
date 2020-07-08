# frozen_string_literal: true

RSpec.describe RailwayIpc::ProcessIncomingMessage, '#call' do
  let(:fake_logger) { RailwayIpc::SpecHelpers::FakeLogger.new }
  let(:fake_handler) { RailwayIpc::SpecHelpers::FakeHandler.new }

  around(:each) do |example|
    original_logger = RailwayIpc.logger.logger
    RailwayIpc.configure(logger: fake_logger)
    example.run
    RailwayIpc.configure(logger: original_logger)
  end

  context 'when the message is valid' do
    let(:protobuf) { stubbed_protobuf }
    let(:payload) { stubbed_payload }
    let(:incoming_message) { RailwayIpc::IncomingMessage.new(payload) }
    let(:fake_handler) { RailwayIpc::SpecHelpers::FakeHandler.new }

    context 'and the consumer provides a handler' do
      it 'executes the message handler using the message' do
        consumer = instance_double(
          RailwayIpc::Consumer,
          queue_name: 'my-queue',
          exchange_name: 'my-exchange',
          get_handler: fake_handler
        )

        process = described_class.new(consumer, incoming_message)
        process.call
        expect(fake_handler.called?).to eq(true)
        expect(fake_handler.handled_message).to eq(protobuf)
      end

      it "creates a new consumed message with the handler's response" do
        consumer = instance_double(
          RailwayIpc::Consumer,
          queue_name: 'my-queue',
          exchange_name: 'my-exchange',
          get_handler: fake_handler
        )

        process = described_class.new(consumer, incoming_message)

        expect {
          process.call
        }.to change {
          RailwayIpc::ConsumedMessage.count
        }.by(1)

        consumed_message = RailwayIpc::ConsumedMessage.last
        expect(consumed_message.uuid).to eq(RailwayIpc::SpecHelpers::DEAD_BEEF_UUID)
        expect(consumed_message.status).to eq('success')
        expect(consumed_message.message_type).to eq('RailwayIpc::Messages::TestMessage')
        expect(consumed_message.user_uuid).to eq(RailwayIpc::SpecHelpers::BAAD_FOOD_UUID)
        expect(consumed_message.correlation_id).to eq(RailwayIpc::SpecHelpers::CAFE_FOOD_UUID)
        expect(consumed_message.queue).to eq('my-queue')
        expect(consumed_message.exchange).to eq('my-exchange')
        expect(consumed_message.encoded_message).to eq(payload)
      end

      it 'sets the correct consumed message status if the handler fails' do
        fake_handler.result = false
        consumer = instance_double(
          RailwayIpc::Consumer,
          queue_name: 'my-queue',
          exchange_name: 'my-exchange',
          get_handler: fake_handler
        )

        process = described_class.new(consumer, incoming_message)
        process.call
        consumed_message = RailwayIpc::ConsumedMessage.last
        expect(consumed_message.status).to eq('failed_to_process')
      end
    end

    context 'and the message has already been processed' do
      it 'does not call the handler, and does not store a new message' do
        consumer = instance_double(
          RailwayIpc::Consumer,
          queue_name: 'my-queue',
          exchange_name: 'my-exchange',
          get_handler: fake_handler
        )
        RailwayIpc::ConsumedMessage.create!(
          uuid: incoming_message.uuid,
          status: 'success',
          message_type: incoming_message.type,
          user_uuid: incoming_message.user_uuid,
          correlation_id: incoming_message.correlation_id,
          queue: consumer.queue_name,
          exchange: consumer.exchange_name,
          encoded_message: incoming_message.payload
        )

        process = described_class.new(consumer, incoming_message)
        expect {
          process.call
        }.not_to change{RailwayIpc::ConsumedMessage.count}
        expect(fake_handler.called?).to eq(false)
      end
    end

    context 'and the consumer does not provide a handler' do
      it 'saves the consumed message with a status of `ignored` and logs that it cannot be handled' do
        consumer = instance_double(
          RailwayIpc::Consumer,
          queue_name: 'my-queue',
          exchange_name: 'my-exchange',
          get_handler: nil
        )

        process = described_class.new(consumer, incoming_message)
        process.call
        consumed_message = RailwayIpc::ConsumedMessage.find_by(uuid: incoming_message.uuid)
        expect(consumed_message.status).to eq('ignored')
        expect(fake_logger.messages[:warn].first).to \
          include(%q{Ignoring message, no registered handler for 'RailwayIpc::Messages::TestMessage'})
      end
    end
  end

  context 'when the message is for a unknown protobuf' do
    it 'saves the consumed message with a status of `unknown`' do
      consumer = instance_double(
        RailwayIpc::Consumer ,
        queue_name: 'my-queue',
        exchange_name: 'my-exchange',
        get_handler: fake_handler
      )

      payload = {
        type: 'Foo',
        encoded_message: Base64.encode64(RailwayIpc::Messages::TestMessage.encode(stubbed_protobuf))
      }.to_json

      incoming_message = RailwayIpc::IncomingMessage.new(payload)
      process = described_class.new(consumer, incoming_message)
      process.call
      consumed_message = RailwayIpc::ConsumedMessage.last
      expect(consumed_message.status).to eq('unknown_message_type')
      expect(consumed_message.encoded_message).to eq(payload)
    end

    it 'logs an warning' do
      consumer = instance_double(
        RailwayIpc::Consumer ,
        queue_name: 'my-queue',
        exchange_name: 'my-exchange',
        get_handler: fake_handler
      )

      payload = {
        type: 'Foo',
        encoded_message: Base64.encode64(RailwayIpc::Messages::TestMessage.encode(stubbed_protobuf))
      }.to_json

      incoming_message = RailwayIpc::IncomingMessage.new(payload)
      process = described_class.new(consumer, incoming_message)
      process.call
      expect(fake_logger.messages[:warn].first).to \
        include("Ignoring unknown message of type 'Foo'")
    end
  end

  context 'when the incoming message is invalid (ie. missing correlation ID)' do
    it 'raises an error, logs a message, and does not store message' do
      consumer = instance_double(RailwayIpc::Consumer)

      payload = {
        type: 'RailwayIpc::Messages::TestMessage',
        encoded_message: Base64.encode64(RailwayIpc::Messages::TestMessage.encode(stubbed_protobuf(correlation_id: '')))
      }.to_json

      incoming_message = RailwayIpc::IncomingMessage.new(payload)
      process = described_class.new(consumer, incoming_message)
      expect {
        process.call
      }.to(raise_error(RailwayIpc::IncomingMessage::InvalidMessage))
      expect(fake_logger.messages[:error].first).to \
        include('Message is invalid: correlation_id is required.')

      expect(RailwayIpc::ConsumedMessage.count).to be_zero
    end
  end
end
