module RailwayIpc
  class NullMessage
    def self.decode(message)
      self.new
    end
  end
end
