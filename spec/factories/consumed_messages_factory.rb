FactoryBot.define do
  factory :consumed_message do
    uuid { SecureRandom.uuid }
    correlation_id { SecureRandom.uuid }
    user_uuid { SecureRandom.uuid }
    encoded_message { "" }
    status { "success" }
    exchange { "ipc:events:test" }
    queue { "source:events:test" }
  end
end
