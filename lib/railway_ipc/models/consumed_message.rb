module RailwayIpc
  class ConsumedMessage < ActiveRecord::Base
    STATUSES = {
      success: 'success',
      processing: 'processing',
      unknown_message_type: 'unknown_message_type'
    }
    attr_reader :decoded_message
    self.table_name = 'railway_ipc_consumed_messages'
    self.primary_key = 'uuid'

    def processed?
      self.status == STATUSES[:success]
    end

    def encoded_protobuf=(encoded_protobuf)
      self.encoded_message = Base64.encode64(encoded_protobuf)
    end

    def decoded_message
      @decoded_message ||= decode_message
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
      message_class.decode(decoded_protobuf)
    end

    def decoded_protobuf
      Base64.decode64(self.encoded_message)
    end
  end
end
