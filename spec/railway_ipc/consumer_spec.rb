RSpec.describe RailwayIpc::Consumer do
  before(:each) do
    allow(RailwayIpc.logger).to receive(:info).and_return(nil)
  end

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

    context 'when a payload is successfully decoded with known message type' do
      context 'when a consumed message with matching uuid exists' do
        context 'when the existing consumed message has an existing status of "success"' do
          let!(:test_message) { test_message_stub }
          let!(:payload) { payload_stub(message: test_message) }
          let!(:delivery_info) { delivery_info_stub }
          let!(:consumed_message) { consumed_message_stub(message: test_message, status: RailwayIpc::ConsumedMessage::STATUSES[:success]) }
          let!(:test_handler) { RailwayIpc::TestHandler.new }

          it 'does not update the record' do
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

        context 'when the existing consumed message has an existing status of "unknown_message_type"' do
          let!(:test_message) { test_message_stub }
          let!(:payload) { payload_stub(message: test_message) }
          let!(:delivery_info) { delivery_info_stub }
          let!(:consumed_message) { consumed_message_stub(message: test_message, status: RailwayIpc::ConsumedMessage::STATUSES[:unknown_message_type]) }

          it 'update process the message and records success status' do
            expect {
              consumer.work_with_params(payload, delivery_info, nil)
            }.to change {
              consumed_message.reload.status
            }.from(RailwayIpc::ConsumedMessage::STATUSES[:unknown_message_type])
            .to(RailwayIpc::ConsumedMessage::STATUSES[:success])
          end

          it 'acks the message' do
            expect_any_instance_of(RailwayIpc::TestHandler).to receive(:ack!)

            consumer.work_with_params(payload, delivery_info, nil)
          end
        end

        context 'when the existing consumed message has an existing status of "processing"' do
          let!(:test_message) { test_message_stub }
          let!(:payload) { payload_stub(message: test_message) }
          let!(:delivery_info) { delivery_info_stub }
          let!(:consumed_message) { consumed_message_stub(message: test_message, status: RailwayIpc::ConsumedMessage::STATUSES[:processing]) }
          let!(:test_handler) { RailwayIpc::TestHandler.new }

          context 'when message is handled successfully' do
            it 'adds a persistence db lock to the consumed message record, processes it, and updates the message with a status of "success"' do
              allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
              allow(test_handler.class.block).to receive(:call).and_return(OpenStruct.new(success?: true))
              expect_any_instance_of(RailwayIpc::ConsumedMessage).to receive(:with_lock).with("FOR UPDATE NOWAIT") do |*_args, &block|
                block.call
                expect(consumed_message.reload.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:success])
              end

              consumer.work_with_params(payload, delivery_info, nil)
            end
          end

          context 'when message fails being handled' do
            it 'adds a persistence db lock to the consumed message record, processes it, and updates the message with a status of "failed_to_process"' do
              allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
              allow(test_handler.class.block).to receive(:call).and_return(OpenStruct.new(success?: false))
              expect_any_instance_of(RailwayIpc::ConsumedMessage).to receive(:with_lock).with("FOR UPDATE NOWAIT") do |*_args, &block|
                block.call
                expect(consumed_message.reload.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:failed_to_process])
              end

              consumer.work_with_params(payload, delivery_info, nil)
            end
          end

          it 'acks the message' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            allow(test_handler.class.block).to receive(:call).and_return(OpenStruct.new(success?: false))
            expect(test_handler).to receive(:ack!)

            consumer.work_with_params(payload, delivery_info, nil)
          end
        end
      end

      context 'when a consumed message with matching uuid does not exist' do
        let!(:test_message) { test_message_stub }
        let!(:payload) { payload_stub(message: test_message) }
        let!(:delivery_info) { delivery_info_stub }
        let!(:test_handler) { RailwayIpc::TestHandler.new }

        context 'when message is handled successfuly' do
          it 'created the record with a status of "processing", added a persistence db lock to the record while processing the the message and updated the message status to "success" after being handled' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            allow(test_handler.class.block).to receive(:call).and_return(OpenStruct.new(success?: true))

            expect_any_instance_of(RailwayIpc::ConsumedMessage).to receive(:with_lock).with("FOR UPDATE NOWAIT") do |*_args, &block|
              consumed_message = RailwayIpc::ConsumedMessage.find(test_message.uuid)
              expect(consumed_message.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:processing])

              block.call
              expect(consumed_message.reload.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:success])
            end
            expect {
              consumer.work_with_params(payload, delivery_info, nil)
            }.to change { RailwayIpc::ConsumedMessage.count }.from(0).to(1)
          end

          it 'acks the message' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            expect(test_handler).to receive(:ack!)

            consumer.work_with_params(payload, delivery_info, nil)
          end
        end

        context 'when message fails being handled' do
          it 'created the record with a status of "processing", added a persistence db lock to the record while processing the the message and updated the message status to "success" after being handled' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            allow(test_handler.class.block).to receive(:call).and_return(OpenStruct.new(success?: false))

            expect_any_instance_of(RailwayIpc::ConsumedMessage).to receive(:with_lock).with("FOR UPDATE NOWAIT") do |*_args, &block|
              consumed_message = RailwayIpc::ConsumedMessage.find(test_message.uuid)
              expect(consumed_message.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:processing])

              block.call
              expect(consumed_message.reload.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:failed_to_process])
            end
            expect {
              consumer.work_with_params(payload, delivery_info, nil)
            }.to change { RailwayIpc::ConsumedMessage.count }.from(0).to(1)
          end

          it 'acks the message' do
            allow(RailwayIpc::TestHandler).to receive(:new).and_return(test_handler)
            allow(test_handler.class.block).to receive(:call).and_return(OpenStruct.new(success?: false))
            expect(test_handler).to receive(:ack!)

            consumer.work_with_params(payload, delivery_info, nil)
          end
        end
      end
    end

    context 'when payload is decoded with unknown message type' do
      context 'when persistence is successful' do
        let!(:test_message) { base_message_stub }
        let!(:payload) { payload_stub(message: test_message) }
        let!(:delivery_info) { delivery_info_stub }
        let!(:payload) { RailwayIpc::Rabbitmq::Payload.encode(test_message) }
        let!(:test_handler) { RailwayIpc::NullHandler.new }

        it 'creates the record with a status of "unknown_message_type"' do
          consumer.work_with_params(payload, delivery_info, nil)
          consumed_message = RailwayIpc::ConsumedMessage.find(test_message.uuid)

          expect(consumed_message.status).to eq(RailwayIpc::ConsumedMessage::STATUSES[:unknown_message_type])
        end

        it 'does not process the message' do
          allow(RailwayIpc::NullHandler).to receive(:new).and_return(test_handler)
          expect(test_handler).not_to receive(:handle)

          consumer.work_with_params(payload, delivery_info, nil)
        end

        it 'acks the message' do
          allow(RailwayIpc::NullHandler).to receive(:new).and_return(test_handler)
          expect(test_handler).to receive(:ack!)

          consumer.work_with_params(payload, delivery_info, nil)
        end
      end

      context 'when persistence fails' do
        let!(:test_message) do
          RailwayIpc::BaseMessage.new(
            uuid: nil,
            correlation_id: nil,
            user_uuid: nil
          )
        end
        let!(:payload) { payload_stub(message: test_message) }
        let!(:delivery_info) { delivery_info_stub }
        let!(:payload) { RailwayIpc::Rabbitmq::Payload.encode(test_message) }
        let!(:test_handler) { RailwayIpc::NullHandler.new }

        it 'raises error' do
          expect {
            consumer.work_with_params(payload, delivery_info, nil)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'acks the message' do
          allow(RailwayIpc::NullHandler).to receive(:new).and_return(test_handler)
          allow(RailwayIpc::ConsumedMessage).to receive(:create!).and_return(nil)
          expect(test_handler).to receive(:ack!)

          consumer.work_with_params(payload, delivery_info, nil)
        end
      end
    end
  end

  private

  def payload_stub(message: create(:test_message), message_klass: LearnIpc::Commands::TestMessage, message_type: nil)
    {
      type: message_type || message.class.to_s,
      encoded_message: Base64.encode64(
        message_klass.encode(message)
      )
    }.to_json
  end

  def base_message_stub
    RailwayIpc::BaseMessage.new(
      uuid: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      user_uuid: SecureRandom.uuid
    )
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

  def consumed_message_stub(
    message: test_message_stub,
    status: RailwayIpc::ConsumedMessage::STATUSES[:success],
    message_type: "LearnIpc::Commands::TestMessage"
  )
    create(
      :consumed_message,
      user_uuid: message.user_uuid,
      correlation_id: message.correlation_id,
      uuid: message.uuid,
      updated_at: 5.minutes.ago,
      status: status,
      message_type: message_type
    )
  end
end
