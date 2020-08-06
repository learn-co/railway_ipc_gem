# frozen_string_literal: true

require_relative './test_message_pb.rb'
require_relative './second_test_handler.rb'

module RailwayIpc
  class SecondTestConsumer < RailwayIpc::Consumer
    listen_to queue: 'ironboard:test:commands', exchange: 'test:events'
    handle RailwayIpc::Messages::TestMessage, with: RailwayIpc::SecondTestHandler
  end
end
