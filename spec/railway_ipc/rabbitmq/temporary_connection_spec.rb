RSpec.describe RailwayIpc::Rabbitmq::TemporaryConnection do
  it 'connects to rabbit with provided credentials' do
    connection = RailwayIpc::Rabbitmq::TemporaryConnection.new(rabbit_adapter: double, queue_name: "my queue", exchange_name: "my exchange")

  end

  xit 'starts rabbit connection and creates channel' do
    rabbit_connection = double("FakeConnection")
    connection_class = double("FakeBunny", new: rabbit_connection)

    options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new(amqp_url: "amqp://me:my_server@localhost:5672", rabbit_adapter: connection_class)
    connection = RailwayIpc::Rabbitmq::TemporaryConnection.new(connection_options: options)
    connection.start
  end
end
