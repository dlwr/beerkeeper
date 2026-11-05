# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_05_000000) do
  create_table "event_cancellations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_cancellations_on_event_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "budget"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_at", precision: nil
    t.string "location"
    t.integer "max_size"
    t.string "name", null: false
    t.integer "organizer_id", null: false
    t.text "participant_notice"
    t.datetime "start_at", precision: nil
    t.datetime "updated_at", null: false
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
  end

  create_table "participations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.boolean "waitlisted", default: false, null: false
    t.index ["event_id", "user_id"], name: "index_participations_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_participations_on_event_id"
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "user_password_credentials", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_user_password_credentials_on_email", unique: true
    t.index ["user_id"], name: "index_user_password_credentials_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "event_cancellations", "events"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "participations", "events"
  add_foreign_key "participations", "users"
  add_foreign_key "user_password_credentials", "users"
end
