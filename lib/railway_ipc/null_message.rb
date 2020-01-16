module RailwayIpc
  class NullMessage
    def self.decode(_message)
      self.new
    end
  end
end
