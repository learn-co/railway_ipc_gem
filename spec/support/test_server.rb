require_relative "./test_request_pb.rb"
require_relative "./test_responder.rb"
require_relative "./rpc_adapter.rb"
require_relative "./timeout_request_pb.rb"
require_relative "./timeout_responder.rb"
require_relative "./error_message_pb.rb"

module RailwayIpc
  class TestServer < RailwayIpc::Server
    listen_to queue: "ipc:test:requests"
    respond_to LearnIpc::Requests::TestRequest, with: RailwayIpc::TestResponder
    respond_to LearnIpc::Requests::TimeoutRequest, with: RailwayIpc::TimeoutResponder
    rpc_error_adapter RailwayIpc::RpcAdapter
    rpc_error_message LearnIpc::ErrorMessage
  end
end
