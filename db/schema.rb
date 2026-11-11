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

ActiveRecord::Schema[8.1].define(version: 2026_11_11_130007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.string "house_no", null: false
    t.string "moo"
    t.string "building"
    t.string "soi"
    t.string "road"
    t.bigint "sub_district_id", null: false
    t.string "postcode", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sub_district_id"], name: "index_addresses_on_sub_district_id"
    t.index ["user_id", "kind"], name: "index_addresses_on_user_id_and_kind", unique: true
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "auctions", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.string "title", null: false
    t.text "description"
    t.decimal "starting_price", precision: 14, scale: 2, null: false
    t.decimal "min_increment", precision: 14, scale: 2, null: false
    t.decimal "current_price", precision: 14, scale: 2
    t.integer "bids_count", default: 0, null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "status", default: "draft", null: false
    t.bigint "winner_id"
    t.datetime "closed_at"
    t.datetime "ending_soon_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_auctions_on_seller_id"
    t.index ["starts_at"], name: "index_auctions_on_starts_at"
    t.index ["status", "ends_at"], name: "index_auctions_on_status_and_ends_at"
    t.index ["winner_id"], name: "index_auctions_on_winner_id"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "bank_code", null: false
    t.string "account_name", null: false
    t.string "account_number", null: false
    t.string "branch"
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bank_accounts_on_user_id"
  end

  create_table "bids", force: :cascade do |t|
    t.bigint "auction_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id", "amount"], name: "index_bids_on_auction_id_and_amount"
    t.index ["auction_id"], name: "index_bids_on_auction_id"
    t.index ["user_id"], name: "index_bids_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "auction_id", null: false
    t.bigint "user_id", null: false
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id"], name: "index_chat_messages_on_auction_id"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "consents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.string "document_version", null: false
    t.datetime "accepted_at", null: false
    t.string "ip_address"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "kind"], name: "index_consents_on_user_id_and_kind"
    t.index ["user_id"], name: "index_consents_on_user_id"
  end

  create_table "districts", force: :cascade do |t|
    t.bigint "province_id", null: false
    t.string "code", null: false
    t.string "name_th", null: false
    t.string "name_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_districts_on_code", unique: true
    t.index ["province_id"], name: "index_districts_on_province_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "auction_id"
    t.string "kind", null: false
    t.string "message", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id"], name: "index_notifications_on_auction_id"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "onboarding_reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "reviewer_id", null: false
    t.string "action", null: false
    t.string "steps_flagged", default: [], null: false, array: true
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewer_id"], name: "index_onboarding_reviews_on_reviewer_id"
    t.index ["user_id"], name: "index_onboarding_reviews_on_user_id"
  end

  create_table "provinces", force: :cascade do |t|
    t.string "code", null: false
    t.string "name_th", null: false
    t.string "name_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_provinces_on_code", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.json "permissions", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sub_districts", force: :cascade do |t|
    t.bigint "district_id", null: false
    t.string "code", null: false
    t.string "name_th", null: false
    t.string "name_en"
    t.string "postcode", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_sub_districts_on_code", unique: true
    t.index ["district_id"], name: "index_sub_districts_on_district_id"
  end

  create_table "user_interests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "categories", default: [], null: false, array: true
    t.string "province_codes", default: [], null: false, array: true
    t.string "notify_channels", default: [], null: false, array: true
    t.string "notify_events", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_interests_on_user_id", unique: true
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "first_name_en"
    t.string "last_name_en"
    t.string "nationality", default: "TH", null: false
    t.string "national_id"
    t.string "passport_no"
    t.date "date_of_birth"
    t.string "gender"
    t.string "line_id"
    t.string "company_name_th"
    t.string "company_name_en"
    t.string "tax_id"
    t.string "company_type"
    t.date "company_registered_on"
    t.boolean "vat_registered", default: false, null: false
    t.string "vat_branch_code"
    t.string "authorized_person_name"
    t.string "authorized_person_national_id"
    t.string "authorized_person_position"
    t.string "contact_person_name"
    t.string "contact_person_phone"
    t.string "contact_person_email"
    t.string "occupation"
    t.string "occupation_other"
    t.string "employer"
    t.string "position"
    t.string "industry"
    t.string "income_range"
    t.string "revenue_range"
    t.string "source_of_funds", default: [], null: false, array: true
    t.string "purpose"
    t.string "budget_range"
    t.boolean "is_pep"
    t.boolean "has_auction_experience"
    t.string "auction_experience_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["national_id"], name: "index_user_profiles_on_national_id", unique: true
    t.index ["tax_id"], name: "index_user_profiles_on_tax_id", unique: true
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone", null: false
    t.string "email_address"
    t.string "password_digest", null: false
    t.string "otp_digest"
    t.datetime "otp_expires_at"
    t.integer "otp_attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "role_id"
    t.string "bidder_type"
    t.string "onboarding_status", default: "in_progress", null: false
    t.integer "onboarding_step", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.decimal "bid_limit", precision: 15, scale: 2
    t.index ["approved_by_id"], name: "index_users_on_approved_by_id"
    t.index ["onboarding_status"], name: "index_users_on_onboarding_status"
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "sub_districts"
  add_foreign_key "addresses", "users"
  add_foreign_key "auctions", "users", column: "seller_id"
  add_foreign_key "auctions", "users", column: "winner_id"
  add_foreign_key "bank_accounts", "users"
  add_foreign_key "bids", "auctions"
  add_foreign_key "bids", "users"
  add_foreign_key "chat_messages", "auctions"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "consents", "users"
  add_foreign_key "districts", "provinces"
  add_foreign_key "notifications", "auctions"
  add_foreign_key "notifications", "users"
  add_foreign_key "onboarding_reviews", "users"
  add_foreign_key "onboarding_reviews", "users", column: "reviewer_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "sub_districts", "districts"
  add_foreign_key "user_interests", "users"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "users", column: "approved_by_id"
end
