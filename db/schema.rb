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

ActiveRecord::Schema[8.1].define(version: 2026_03_02_212636) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "followings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "following_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["following_id"], name: "index_followings_on_following_id"
    t.index ["user_id"], name: "index_followings_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "bsky_uri"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "remote_followers", force: :cascade do |t|
    t.string "actor_uri", null: false
    t.datetime "created_at", null: false
    t.string "inbox_url", null: false
    t.string "shared_inbox_url"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "actor_uri"], name: "index_remote_followers_on_user_id_and_actor_uri", unique: true
    t.index ["user_id"], name: "index_remote_followers_on_user_id"
  end

  create_table "remote_replies", force: :cascade do |t|
    t.string "activity_uri", null: false
    t.string "actor_name"
    t.string "actor_uri", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "published_at"
    t.datetime "updated_at", null: false
    t.index ["activity_uri"], name: "index_remote_replies_on_activity_uri", unique: true
    t.index ["post_id"], name: "index_remote_replies_on_post_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "bsky_app_password"
    t.string "bsky_handle"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email_address", null: false
    t.string "location"
    t.string "password_digest", null: false
    t.text "private_key"
    t.text "public_key"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "followings", "followings"
  add_foreign_key "followings", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "remote_followers", "users"
  add_foreign_key "remote_replies", "posts"
  add_foreign_key "sessions", "users"
end
