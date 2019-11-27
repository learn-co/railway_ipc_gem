module RailwayIpc
  ConsumerHandlerManifest = Struct.new(:handler_class, :message_class) do
    def fetch(key, default = nil)
      self[key] || default
    end
  end
  class ConsumerResponseHandlers
    include Singleton

    def registered
      handler_map.keys
    end
    def register(message, handler:)
      handler_map[message.to_s] = ConsumerHandlerManifest.new(handler, message)
    end

    def get(message)
      handler_map[message]
    end

    private

    def handler_map
      @handler_map ||= {}
    end
  end
end
