RSpec.describe RailwayIpc::Rabbitmq::Adapter do
  it "connects to rabbit" do
    options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new(amqp_url: "amqp://guest:guest@localhost:5672", rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
    connection = RailwayIpc::Rabbitmq::Adapter.new(connection_options: options)
    connection.start
    expect(connection.connected?).to be_truthy
  end

  it "creates an exchange and connected queue" do
    options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new(amqp_url: "amqp://guest:guest@localhost:5672", rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
    connection = RailwayIpc::Rabbitmq::Adapter.new(connection_options: options)
    connection.start
    exchange = connection.create_exchange(exchange_name: "my_exchange")
    connection.create_queue(exchange: exchange, exchange_name: "my_exchange")
  end
end
