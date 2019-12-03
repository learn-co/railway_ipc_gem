RSpec.describe RailwayIpc::Rabbitmq::TemporaryConnection do
  it 'connects to rabbit with provided credentials' do
    options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new(amqp_url: "amqp://me:my_server@localhost:5672", rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
    connection = RailwayIpc::Rabbitmq::TemporaryConnection.new(connection_options: options)

    expect(connection.rabbit_connection).to be_a(RailwayIpc::Rabbitmq::Adapter)
    expect(connection.rabbit_connection.host).to eq("localhost")
    expect(connection.rabbit_connection.port).to eq(5672)
    expect(connection.rabbit_connection.user).to eq("me")
    expect(connection.rabbit_connection.pass).to eq("my_server")
    expect(connection.rabbit_connection.automatically_recover?).to be_falsey
    expect(connection.rabbit_connection.logger).to eq(RailwayIpc.bunny_logger)
  end

  it 'starts rabbit connection and creates channel' do
    rabbit_connection = double("FakeConnection")
    connection_class = double("FakeBunny", new: rabbit_connection)

    options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new(amqp_url: "amqp://me:my_server@localhost:5672", rabbit_adapter: connection_class)
    connection = RailwayIpc::Rabbitmq::TemporaryConnection.new(connection_options: options)
    connection.start
  end
end
