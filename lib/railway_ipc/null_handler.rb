module RailwayIpc
  class NullHandler < RailwayIpc::Handler
    def handle(message)
      nil
    end
  end
end
