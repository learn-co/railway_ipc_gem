# frozen_string_literal: true

module RailwayIpc
  class Handler
    class << self
      attr_reader :block
    end

    def self.handle(&block)
      @block = block
    end

    def handle(message)
      RailwayIpc.logger.info('Handling message', protobuf: message)
      response = self.class.block.call(message)
      if response.success?
        RailwayIpc.logger.info('Successfully handled message', protobuf: message)
      else
        RailwayIpc.logger.error('Failed to handle message', protobuf: message)
      end

      response
    end
  end
end
