# frozen_string_literal: true

require_relative './test_message_pb'
require_relative './second_test_handler'

module RailwayIpc
  class SecondTestConsumer < RailwayIpc::Consumer
    listen_to queue: 'ironboard:test:commands', exchange: 'test:events'
    handle RailwayIpc::Messages::TestMessage, with: RailwayIpc::SecondTestHandler
  end
end
