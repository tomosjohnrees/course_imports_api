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

ActiveRecord::Schema[8.1].define(version: 2026_03_10_085511) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "courses", force: :cascade do |t|
    t.string "author_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "external_id"
    t.string "github_owner", null: false
    t.string "github_repo", null: false
    t.string "github_repo_url", null: false
    t.datetime "last_validated_at"
    t.integer "load_count", default: 0
    t.integer "repo_size_kb"
    t.string "status", default: "pending", null: false
    t.string "tags", default: [], array: true
    t.string "title", null: false
    t.integer "topic_count"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "validation_error"
    t.string "version"
    t.index ["github_owner", "github_repo"], name: "index_courses_on_github_owner_and_github_repo", unique: true
    t.index ["status"], name: "index_courses_on_status"
    t.index ["tags"], name: "index_courses_on_tags", using: :gin
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.boolean "banned", default: false, null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "github_id", null: false
    t.string "github_token"
    t.string "github_username", null: false
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
  end

  create_table "validation_attempts", force: :cascade do |t|
    t.integer "api_calls_made"
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "result"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_validation_attempts_on_course_id"
  end

  add_foreign_key "courses", "users"
  add_foreign_key "validation_attempts", "courses"
end
