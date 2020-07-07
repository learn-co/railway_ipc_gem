class RailwayIpc::Error < StandardError; end
class RailwayIpc::InvalidProtobuf < RailwayIpc::Error; end
class RailwayIpc::IncomingMessage::ParserError < RailwayIpc::Error; end
class RailwayIpc::IncomingMessage::InvalidMessage < RailwayIpc::Error; end
