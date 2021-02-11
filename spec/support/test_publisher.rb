# frozen_string_literal: true

module RailwayIpc
  class TestPublisher < RailwayIpc::Publisher
    def initialize
      super(exchange_name: 'test:events')
    end
  end
end
