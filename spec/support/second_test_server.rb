require_relative "./test_request_pb.rb"
require_relative "./second_test_responder.rb"
require_relative "./rpc_adapter.rb"
require_relative "./error_message_pb.rb"

module RailwayIpc
  class SecondTestServer < RailwayIpc::Server
    listen_to queue: "ipc:second_test:requests", exchange: "ipc:test:requests"
    respond_to LearnIpc::Requests::TestRequest, with: RailwayIpc::SecondTestResponder
    rpc_error_adapter RailwayIpc::RpcAdapter
  end
end
