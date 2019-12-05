require_relative "./i_spec.rb"

ISpec.describe "Request Response Cycle" do
  ISpec.before do
    server = RailwayIpc::TestServer.new
    server.run
  end

  ISpec.context "when success" do
    ISpec.it "returns the requested document" do
      response = RailwayIpc::TestClient.request_documents("1234")
      response.body.is_a?(LearnIpc::Documents::TestDocument)
    end
  end

  ISpec.context "when the server receives and unhandled message" do
    ISpec.it "returns the unhandled message error message" do
      response = RailwayIpc::TestClient.unhandled_message("1234")
      response.is_a?(RailwayIpc::Response) && response.body.data.error == "RailwayIpc::UnhandledMessageError"
    end
  end

  ISpec.context "when the server times out" do
    ISpec.it "returns the timeout error message" do
      response = RailwayIpc::TestClient.timeout_message("1234")
      p response
      # Currently "RailwayIpc::Rabbitmq::Adapter::TimeoutError"
      response.is_a?(RailwayIpc::Response) && response.body.data.error == "RailwayIpc::Client::TimeoutError"
    end
  end
end
