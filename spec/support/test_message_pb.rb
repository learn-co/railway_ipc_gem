# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: commands/create_batch.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "railway_ipc.messages.TestMessage" do
    optional :user_uuid, :string, 1
    optional :correlation_id, :string, 2
    optional :uuid, :string, 3
    map :context, :string, :string, 4
    optional :data, :message, 5, "railway_ipc.messages.TestMessage.Data"
  end
  add_message "railway_ipc.messages.TestMessage.Data" do
    optional :param, :string, 1
  end
end

module RailwayIpc
  module Messages
    TestMessage = Google::Protobuf::DescriptorPool.generated_pool.lookup("railway_ipc.messages.TestMessage").msgclass
    TestMessage::Data = Google::Protobuf::DescriptorPool.generated_pool.lookup("railway_ipc.messages.TestMessage.Data").msgclass
  end
end
