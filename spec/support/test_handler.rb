# frozen_string_literal: true

require 'ostruct'
module RailwayIpc
  class TestHandler < RailwayIpc::Handler
    handle do |_message|
      OpenStruct.new({ success?: true })
    end
  end
end
