# frozen_string_literal: true

RSpec.describe RailwayIpc::Rabbitmq::Adapter do
  let(:connection) do
    RailwayIpc::Rabbitmq::Adapter.new(queue_name: 'test_queue', exchange_name: 'test_exchange')
  end

  after(:each) do
    connection.connect
    connection.delete_exchange
    connection.delete_queue
  end

  context 'connecting' do
    it 'connects to rabbit' do
      connection.connect
      expect(connection.connected?).to be_truthy
      expect(connection.automatically_recover?).to be_falsey
    end
    it 'accepts options' do
      diff_connection = RailwayIpc::Rabbitmq::Adapter.new(queue_name: 'test_queue', exchange_name: 'test_exchange', options: { automatic_recovery: true })
      expect(diff_connection).to be_automatically_recover
    end
  end

  context 'creating an exchange' do
    it 'creates an exchange' do
      connection
        .connect
        .create_exchange
      expect(connection.exchange.name).to eq('test_exchange')
      expect(connection.exchange.type).to eq(:fanout)
      expect(connection.exchange).to be_durable
      expect(connection.exchange).to_not be_auto_delete
    end

    it 'accepts options' do
      connection
        .connect
        .create_exchange(options: { auto_delete: true })
      expect(connection.exchange).to_not be_durable
      expect(connection.exchange).to be_auto_delete
    end
  end

  context 'creating a queue' do
    it 'creates and binds queue' do
      connection
        .connect
        .create_exchange
        .create_queue
        .bind_queue_to_exchange
      expect(connection.queue.name).to eq('test_queue')
      connection.publish('hello there', routing_key: 'my_key')
      connection.check_for_message do |delivery_info, _properties, payload|
        expect(delivery_info.routing_key).to eq('my_key')
        expect(payload).to eq('hello there')
      end
    end

    it 'accepts options' do
      connection
        .connect
        .create_exchange
        .create_queue(auto_delete: true, exclusive: true)
      expect(connection.queue.auto_delete?).to eq(true)
      expect(connection.queue.exclusive?).to eq(true)
    end
    it 'creates queue name if none provided' do
      temp_conn = RailwayIpc::Rabbitmq::Adapter.new(exchange_name: 'test_exchange')
                                               .connect
                                               .create_queue(auto_delete: true, exclusive: true)
      expect(temp_conn.queue.name).to match(/^amq.gen/)
    end
  end
end
