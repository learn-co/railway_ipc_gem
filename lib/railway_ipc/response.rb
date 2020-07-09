# frozen_string_literal: true

module RailwayIpc
  class Response
    attr_reader :body, :success

    def initialize(message, success: true)
      @body = message
      @success = success
    end
  end
end
