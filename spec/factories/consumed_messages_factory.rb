# frozen_string_literal: true

FactoryBot.define do
  factory :consumed_message, class: RailwayIpc::ConsumedMessage do
    uuid { SecureRandom.uuid }
    correlation_id { SecureRandom.uuid }
    user_uuid { SecureRandom.uuid }
    encoded_message { Base64.encode64(SecureRandom.hex) }
    message_type { "RailwayIpc::Messages::TestMessage" }
    status { RailwayIpc::ConsumedMessage::STATUS_SUCCESS }
    exchange { "ipc:events:test" }
    queue { "source:events:test" }
  end
end
