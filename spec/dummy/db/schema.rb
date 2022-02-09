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

ActiveRecord::Schema.define(version: 2021_11_10_113140) do

  create_table "systems", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title", limit: 100, null: false
    t.string "uuid", limit: 40, null: false
    t.string "public", limit: 40, null: false
    t.integer "ttl", default: 3600, null: false
    t.integer "state", default: 0, null: false
    t.json "jwk"
    t.json "request_uri"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["public"], name: "index_systems_on_public", unique: true
    t.index ["uuid"], name: "index_systems_on_uuid", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", limit: 100, null: false
    t.string "name", limit: 100, null: false
    t.string "surname", limit: 100, null: false
    t.string "timezone", limit: 30, null: false
    t.string "locale", limit: 10, default: "ru-RU", null: false
    t.string "password_digest", limit: 60, null: false
    t.string "uuid", limit: 40, null: false
    t.string "public", limit: 40, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["public"], name: "index_users_on_public", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

end
