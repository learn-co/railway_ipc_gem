# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141231134904) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "railway_ipc_published_messages", id: false, force: :cascade do |t|
    t.uuid     "uuid",            null: false
    t.string   "message_type",    null: false
    t.uuid     "user_uuid"
    t.uuid     "correlation_id"
    t.text     "encoded_message", null: false
    t.string   "status",          null: false
    t.string   "queue"
    t.string   "exchange"
    t.datetime "updated_at"
    t.datetime "inserted_at"
    t.index ["uuid"], name: "index_railway_ipc_published_messages_on_uuid", unique: true, using: :btree
  end

end
