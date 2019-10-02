module RailwayIpc
  class NullHandler < RailwayIpc::Handler
    def handle(message)
      ack!
    end
  end
end
