FactoryBot.define do
  factory :test_message, class: LearnIpc::Commands::TestMessage do
    uuid { SecureRandom.uuid }
    correlation_id { SecureRandom.uuid }
    user_uuid { SecureRandom.uuid }
    data { LearnIpc::Commands::TestMessage::Data.new(iteration: "bk-001") }
  end
end
