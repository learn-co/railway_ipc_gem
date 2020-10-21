# frozen_string_literal: true

require_relative './test_document_pb'
module RailwayIpc
  class TestResponder < RailwayIpc::Responder
    respond do |message|
      LearnIpc::Documents::TestDocument.new(correlation_id: message.correlation_id, user_uuid: message.user_uuid)
    end
  end
end
