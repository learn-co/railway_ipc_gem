# frozen_string_literal: true

require 'railway_ipc/handler_manifest'
module RailwayIpc
  class HandlerStore
    attr_reader :handler_map
    def initialize
      @handler_map = {}
    end

    def registered
      handler_map.keys
    end

    def register(message:, handler:)
      handler_map[message.to_s] = HandlerManifest.new(message: message, handler: handler)
    end

    def get(response_message)
      handler_map[response_message]
    end
  end
end
