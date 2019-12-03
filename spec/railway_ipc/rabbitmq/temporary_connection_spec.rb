RSpec.describe RailwayIpc::Rabbitmq::TemporaryConnection do
  it 'connects to rabbit with provided credentials' do
    options = RailwayIpc::Rabbitmq::RabbitConnectionOptions.new("amqp://me:my_server@localhost:5672", Bunny, {autmatic_recovery: true})
    connection = RailwayIpc::Rabbitmq::TemporaryConnection.new(connection_options: options)

    expect(connection.rabbit_connection).to be_a(Bunny::Session)
    expect(connection.rabbit_connection.host).to eq("localhost")
    expect(connection.rabbit_connection.port).to eq(5672)
    expect(connection.rabbit_connection.user).to eq("me")
    expect(connection.rabbit_connection.pass).to eq("my_server")
    expect(connection.rabbit_connection.automatically_recover?).to be_truthy
    expect(connection.rabbit_connection.logger).to eq(RailwayIpc.bunny_logger)
  end
end
