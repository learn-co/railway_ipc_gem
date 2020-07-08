require 'ostruct'
module RailwayIpc
  class SecondTestHandler < RailwayIpc::Handler
    handle do |message|
      OpenStruct.new({success?: true})
    end
  end
end
