# frozen_string_literal: true

module RailwayIpc
  class ConsumedMessage < ActiveRecord::Base
    STATUS_SUCCESS = 'success'
    STATUS_PROCESSING = 'processing'
    STATUS_IGNORED = 'ignored'
    STATUS_UNKNOWN_MESSAGE_TYPE = 'unknown_message_type'
    STATUS_FAILED_TO_PROCESS = 'failed_to_process'

    VALID_STATUSES = [
      STATUS_SUCCESS,
      STATUS_PROCESSING,
      STATUS_IGNORED,
      STATUS_UNKNOWN_MESSAGE_TYPE,
      STATUS_FAILED_TO_PROCESS
    ].freeze

    attr_reader :decoded_message

    self.table_name = 'railway_ipc_consumed_messages'
    self.primary_key = 'uuid'

    validates :uuid, :status, presence: true
    validates :status, inclusion: { in: VALID_STATUSES }

    def self.create_processing(consumer, incoming_message)
      # rubocop:disable Style/RedundantSelf
      self.create!(
        uuid: incoming_message.uuid,
        status: STATUS_PROCESSING,
        message_type: incoming_message.type,
        user_uuid: incoming_message.user_uuid,
        correlation_id: incoming_message.correlation_id,
        queue: consumer.queue_name,
        exchange: consumer.exchange_name,
        encoded_message: incoming_message.payload
      )
      # rubocop:enable Style/RedundantSelf
    end

    def update_with_lock(job)
      transaction do
        # We're using the .lock instead of #lock since #lock reloads the recording using the primary
        # to find it. Our primary key is a composite key, which older versions of ActiveRecord
        # don't support without a gem.

        _message = self.class.lock('FOR UPDATE NOWAIT').find_by(uuid: uuid, queue: queue)
        job.run
        self.class.where(uuid: uuid, queue: queue).update(status: job.status)
        reload
      end
    end

    def processed?
      # rubocop:disable Style/RedundantSelf
      self.status == STATUS_SUCCESS
      # rubocop:enable Style/RedundantSelf
    end

    private

    def timestamp_attributes_for_create
      super << :inserted_at
    end
  end
end
