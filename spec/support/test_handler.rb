require 'ostruct'
module RailwayIpc
  class TestHandler < RailwayIpc::Handler
    handle do |message|
      OpenStruct.new({success?: true})
    end
  end
end
