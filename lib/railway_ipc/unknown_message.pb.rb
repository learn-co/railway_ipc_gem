# frozen_string_literal: true

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message 'railway_ipc.messages.Unknown' do
    optional :user_uuid, :string, 1
    optional :correlation_id, :string, 2
    optional :uuid, :string, 3
    map :context, :string, :string, 4
  end
end

module RailwayIpc
  module Messages
    Unknown = Google::Protobuf::DescriptorPool.generated_pool.lookup('railway_ipc.messages.Unknown').msgclass
  end
end
