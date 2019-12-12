module RailwayIpc
  class PublishedMessage < ActiveRecord::Base
    self.table_name = 'railway_ipc_published_messages'
  end
end
