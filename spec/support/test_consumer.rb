# frozen_string_literal: true

require_relative './test_message_pb'
require_relative './test_handler'

module RailwayIpc
  class TestConsumer < RailwayIpc::Consumer
    listen_to queue: 'ironboard:test:commands', exchange: 'test:events'
    handle RailwayIpc::Messages::TestMessage, with: RailwayIpc::TestHandler
  end
end
