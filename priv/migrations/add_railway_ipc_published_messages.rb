class AddIpcMessages < ActiveRecord::Migration
  def change
    create_table :railway_ipc_published_messages do | t |
      t.uuid :uuid, null: false, default: "uuid_generate_v4()"
      t.string :message_type, null: false
      t.uuid :user_uuid
      t.uuid :correlation_id
      t.text :encoded_message, null: false
      t.string :status, null: false
      t.string :queue
      t.string :exchange

      t.datetime :updated_at
      t.datetime :inserted_at
    end
  end
end
