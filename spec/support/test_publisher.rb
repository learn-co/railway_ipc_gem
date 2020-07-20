# frozen_string_literal: true

module RailwayIpc
  class TestPublisher < RailwayIpc::SingletonPublisher
    exchange 'test:events'
  end
end
