module RailwayIpc
  class ConsumedMessage < ActiveRecord::Base
    SUCCESS_STATUS = "success"
    COMPLETED_STATUSES = %w(success ignore)
    attr_reader :decoded_message
    self.table_name = 'railway_ipc_consumed_messages'
    self.primary_key = 'uuid'

    def self.persist(decoded_message, &handler)
      message = self.find_by(uuid: decoded_message.uuid)

      if message
        # do stuff
        # lock the db row
        # handle the message
        # save the message status
        # unlock the db row
        # return the value of the message
        response = handler.call
        # if response.success?

      else
        # create the record
        # lock the db row
        # handle the message
        # save the message status
        # unlock the db row
        # return the value of the message
      end

    end

    def processed?
      COMPLETED_STATUSES.exclude?(self.status)
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
