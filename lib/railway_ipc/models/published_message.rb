# frozen_string_literal: true

module RailwayIpc
  class PublishedMessage < ActiveRecord::Base
    self.table_name = 'railway_ipc_published_messages'
    self.primary_key = 'uuid'

    validates :uuid, :status, presence: true

    def self.store_message(outgoing_message)
      create!(
        uuid: outgoing_message.uuid,
        message_type: outgoing_message.type,
        user_uuid: outgoing_message.user_uuid,
        correlation_id: outgoing_message.correlation_id,
        encoded_message: outgoing_message.encoded,
        status: 'sent',
        exchange: outgoing_message.exchange
      )
    end

    private

    def timestamp_attributes_for_create
      super << :inserted_at
    end
  end
end
