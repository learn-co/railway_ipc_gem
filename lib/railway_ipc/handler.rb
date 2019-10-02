module RailwayIpc
  class Handler
    include Sneakers::Worker
    class << self
      attr_reader :block
    end

    def self.handle(&block)
      @block = block
    end

    def handle(message)
      RailwayIpc.logger.info(message, "Handling message")
      response = self.class.block.call(message)
      if response.success?
        RailwayIpc.logger.info(message, "Successfully handled message")
        ack!
      else
        RailwayIpc.logger.error(message, "Failed to handle message")
        ack!
      end
    end
  end
end
