FactoryBot.define do
  factory :consumed_message, class: RailwayIpc::ConsumedMessage do
    uuid { SecureRandom.uuid }
    correlation_id { SecureRandom.uuid }
    user_uuid { SecureRandom.uuid }
    encoded_message { "" }
    message_type { "LearnIpc::Commands::TestMessage" }
    status { RailwayIpc::ConsumedMessage::SUCCESS_STATUS }
    exchange { "ipc:events:test" }
    queue { "source:events:test" }
  end
end