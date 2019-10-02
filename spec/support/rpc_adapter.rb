require_relative "./error_message_pb.rb"
module RailwayIpc
  class RpcAdapter
    def self.error_message(error, message)
      data = LearnIpc::ErrorMessage::Data.new(
        error: error.class.to_s,
        error_message: error.message)

      LearnIpc::ErrorMessage.new(
        correlation_id: message.correlation_id,
        user_uuid: message.user_uuid,
        data: data
      )
    end
  end
end
