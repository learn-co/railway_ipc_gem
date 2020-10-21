# frozen_string_literal: true

require_relative './test_request_pb'
require_relative './test_responder'
require_relative './rpc_adapter'
require_relative './timeout_request_pb'
require_relative './timeout_responder'
require_relative './error_message_pb'

module RailwayIpc
  class TestServer < RailwayIpc::Server
    listen_to queue: 'ipc:test:requests', exchange: 'ipc:test:requests'
    respond_to LearnIpc::Requests::TestRequest, with: RailwayIpc::TestResponder
    respond_to LearnIpc::Requests::TimeoutRequest, with: RailwayIpc::TimeoutResponder
    rpc_error_adapter RailwayIpc::RpcAdapter
  end
end
