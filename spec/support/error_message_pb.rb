# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: errors/error_message.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "learn_ipc.ErrorMessage" do
    optional :user_uuid, :string, 1
    optional :correlation_id, :string, 2
    optional :uuid, :string, 3
    optional :reply_to, :string, 4
    map :context, :string, :string, 5
    optional :data, :message, 6, "learn_ipc.ErrorMessage.Data"
  end
  add_message "learn_ipc.ErrorMessage.Data" do
    optional :error, :string, 1
    optional :error_message, :string, 2
  end
end

module LearnIpc
  ErrorMessage = Google::Protobuf::DescriptorPool.generated_pool.lookup("learn_ipc.ErrorMessage").msgclass
  ErrorMessage::Data = Google::Protobuf::DescriptorPool.generated_pool.lookup("learn_ipc.ErrorMessage.Data").msgclass
end
