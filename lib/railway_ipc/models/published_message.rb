module RailwayIpc
  class PublishedMessage < ActiveRecord::Base
    self.table_name = 'railway_ipc_published_messages'
    self.primary_key = "uuid"

    private

    def timestamp_attributes_for_create
      super << :inserted_at
    end
  end
end