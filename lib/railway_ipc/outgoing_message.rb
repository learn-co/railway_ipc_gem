# frozen_string_literal: true

module RailwayIpc
  class OutgoingMessage
    extend Forwardable

    attr_reader :proto

    def initialize(proto)
      @proto = proto
    end

    def type
      proto.class.to_s
    end
  end
end
