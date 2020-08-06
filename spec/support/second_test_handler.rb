# frozen_string_literal: true

require 'ostruct'

module RailwayIpc
  class SecondTestHandler < RailwayIpc::Handler
    handle do
      OpenStruct.new({ success?: true })
    end
  end
end
