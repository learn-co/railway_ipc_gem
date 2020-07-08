# frozen_string_literal: true

require_relative "./i_spec.rb"

RSpec.describe "Request Response Cycle" do
  before do
    server = RailwayIpc::TestServer.new
    server.run
  end

  context "when success" do
    it "returns the requested document" do
      response = RailwayIpc::TestClient.request_documents("1234")
      expect(response.body).to be_a(LearnIpc::Documents::TestDocument)
    end
  end

  context "when the server receives and unhandled message" do
    it "returns the unhandled message error message" do
      response = RailwayIpc::TestClient.unhandled_message("1234")
      response.body.is_a?(LearnIpc::ErrorMessage) && response.body.data.error == "RailwayIpc::UnhandledMessageError"
    end
  end

  context "when the server times out" do
    it "returns the timeout error message" do
      response = RailwayIpc::TestClient.timeout_message("1234")
      response.body.is_a?(LearnIpc::ErrorMessage) && response.body.data.error == "RailwayIpc::Client::TimeoutError"
    end
  end
end
