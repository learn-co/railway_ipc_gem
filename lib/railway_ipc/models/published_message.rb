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

    # rails <= 5.1 uses this method to know the name of the created_at/updated_at fields
    def timestamp_attributes_for_create
      super << :inserted_at
    end

    # rails >= 6.0 moved this to the class level and uses strings instead of symbols
    class << self
      private

      def timestamp_attributes_for_create
        super << 'inserted_at'
      end
    end
  end
end
