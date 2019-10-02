module RailwayIpc
  class TestPublisher < RailwayIpc::Publisher
    exchange 'test:commands'
  end
end
