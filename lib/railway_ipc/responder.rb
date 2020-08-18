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
      RailwayIpc.logger.info('Responding to request', request: request)
      response = self.class.block.call(request)
      raise ResponseTypeError.new(response.class) unless response.is_a?(Google::Protobuf::MessageExts)

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
