# frozen_string_literal: true

class AddRailwayIpcPublishedMessages < ActiveRecord::Migration
  def change
    create_table :railway_ipc_published_messages do |t|
      t.uuid :uuid, null: false
      t.string :message_type
      t.uuid :user_uuid
      t.uuid :correlation_id
      t.text :encoded_message
      t.string :status, null: false
      t.string :exchange

      t.datetime :updated_at
      t.datetime :inserted_at
    end

    add_index :railway_ipc_published_messages, :uuid, unique: true
  end
end
