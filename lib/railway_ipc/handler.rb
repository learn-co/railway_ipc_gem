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
      RailwayIpc.logger.info('Handling message', log_message_options(message))
      response = self.class.block.call(message)
      if response.success?
        RailwayIpc.logger.info('Successfully handled message', log_message_options(message))
      else
        RailwayIpc.logger.error('Failed to handle message', log_message_options(message))
      end

      response
    end

    private

    def log_message_options(message)
      {
        feature: 'railway_ipc_consumer',
        protobuf: {
          type: message.class.name,
          data: message
        }
      }
    end
  end
end
