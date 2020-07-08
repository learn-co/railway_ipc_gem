# frozen_string_literal: true

module RailwayIpc
  class Responder
    def self.respond(&block)
      @block = block
    end

    class << self
      attr_reader :block
    end

    def respond(request)
      RailwayIpc.logger.info(request, 'Responding to request')
      response = self.class.block.call(request)
      unless response.is_a?(Google::Protobuf::MessageExts)
        raise ResponseTypeError, response.class
      end

      response
    end

    class ResponseTypeError < StandardError
      def initialize(response_class)
        message = "`respond` block should return a Google Protobuf message that the corresponding client can handle, instead returned #{response_class}"
        super(message)
      end
    end
  end
end
