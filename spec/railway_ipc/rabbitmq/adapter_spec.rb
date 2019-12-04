RSpec.describe RailwayIpc::Rabbitmq::Adapter do

  let(:connection) do
      options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new(amqp_url: "amqp://guest:guest@localhost:5672", queue: "test_queue", exchange: "test_exchange")
      RailwayIpc::Rabbitmq::Adapter.new(connection_options: options)
  end

  after(:each) do
    connection.connect
    connection.delete_exchange
    connection.delete_queue
  end

  it "connects to rabbit" do
    connection.connect
    expect(connection.connected?).to be_truthy
    expect(connection.automatically_recover?).to be_falsey
  end

  context "creating an exchange" do
    it "creates an exchange" do
      connection
          .connect
          .create_exchange
      expect(connection.exchange.name).to eq("test_exchange")
      expect(connection.exchange.type).to eq(:fanout)
      expect(connection.exchange).to be_durable
      expect(connection.exchange).to_not be_auto_delete
    end

    it "accepts options" do
      connection
          .connect
          .create_exchange(options: {auto_delete: true})
      expect(connection.exchange).to_not be_durable
      expect(connection.exchange).to be_auto_delete
    end
  end

  context "creating a queue" do
    it "creates and binds queue" do
      connection
          .connect
          .create_exchange
          .create_queue
      expect(connection.queue.name).to eq("test_queue")
      connection.publish("hello there", routing_key: "my_key")
      connection.check_for_message do |delivery_info, _properties, payload|
        expect(delivery_info.routing_key).to eq("my_key")
        expect(payload).to eq("hello there")
      end
    end

    it "accepts options" do
      connection
          .connect
          .create_exchange
          .create_queue
    end
  end
end
