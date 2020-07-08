# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class RailwayIpc::Error < StandardError; end
class RailwayIpc::InvalidProtobuf < RailwayIpc::Error; end
class RailwayIpc::IncomingMessage::ParserError < RailwayIpc::Error; end
class RailwayIpc::IncomingMessage::InvalidMessage < RailwayIpc::Error; end
# rubocop:enable Style/ClassAndModuleChildren
