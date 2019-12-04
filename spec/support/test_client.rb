require_relative "./test_request_pb.rb"
require_relative "./unhandled_request_pb.rb"
require_relative "./test_document_pb.rb"
require_relative "./rpc_adapter.rb"
require_relative "./timeout_request_pb.rb"
require_relative "./error_message_pb"

module RailwayIpc
  class TestClient < RailwayIpc::Client
    publish_to exchange: "ipc:test:requests"
    handle_response LearnIpc::Documents::TestDocument
    rpc_error_adapter RailwayIpc::RpcAdapter
    rpc_error_message LearnIpc::ErrorMessage

    def self.request_documents(user_uuid)
      message = LearnIpc::Requests::TestRequest.new(
        user_uuid: user_uuid,
        correlation_id: "56789")
      request(message)
    end

    def self.unhandled_message(user_uuid)
      message = LearnIpc::Requests::UnhandledRequest.new(
        user_uuid: user_uuid,
        correlation_id: "56789")
      request(message)
    end

    def self.timeout_message(user_uuid)
      message = LearnIpc::Requests::TimeoutRequest.new(
        user_uuid: user_uuid,
        correlation_id: "56789")
      request(message)
    end
  end
end
