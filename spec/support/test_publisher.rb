# frozen_string_literal: true

module RailwayIpc
  class TestPublisher < RailwayIpc::Publisher
    exchange 'test:events'
  end
end
