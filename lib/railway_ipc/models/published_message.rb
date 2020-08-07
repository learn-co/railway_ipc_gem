# frozen_string_literal: true

module RailwayIpc
  class PublishedMessage < ActiveRecord::Base
    self.table_name = 'railway_ipc_published_messages'
    self.primary_key = 'uuid'

    validates :uuid, :status, presence: true

    def self.store_message(exchange_name, message)
      encoded_message = RailwayIpc::Rabbitmq::Payload.encode(message)
      create!(
        uuid: message.uuid,
        message_type: message.class.to_s,
        user_uuid: message.user_uuid,
        correlation_id: message.correlation_id,
        encoded_message: encoded_message,
        status: 'sent',
        exchange: exchange_name
      )
    end

    private

    def timestamp_attributes_for_create
      super << :inserted_at
    end
  end
end
