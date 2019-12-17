module RailwayIpc
  class TestPublisher < RailwayIpc::Publisher
    exchange 'test:events'
  end
end
