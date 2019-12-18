module RailwayIpc
  class ConsumedMessage < ActiveRecord::Base
    COMPLETED_STATUSES = %w(success ignore)
    attr_accessor :decoded_message
    after_initialize :decode_message
    self.table_name = 'railway_ipc_consumed_messages'
    self.primary_key = 'uuid'

    def processed?
      COMPLETED_STATUSES.exclude?(self.status)
    end

    private

    def timestamp_attributes_for_create
      super << :inserted_at
    end

    def decode_message
      begin
        message_class = Kernel.const_get(self.message_type)
      rescue NameError
        message_class = RailwayIpc::BaseMessage
      end
      self.decoded_message = message_class.decode(self.encoded_message)
    end
  end
end
