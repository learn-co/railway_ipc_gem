# frozen_string_literal: true

module RailwayIpc
  class HandlerManifest
    attr_reader :message, :handler

    def initialize(message:, handler:)
      @message = message
      @handler = handler
    end
  end
end
