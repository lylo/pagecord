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

ActiveRecord::Schema[8.1].define(version: 2025_09_22_135220) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "access_requests", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_access_requests_on_expires_at"
    t.index ["token_digest"], name: "index_access_requests_on_token_digest", unique: true
    t.index ["user_id"], name: "index_access_requests_on_user_id"
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["body"], name: "index_action_text_rich_texts_on_body_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["record_type", "name", "record_id"], name: "index_action_text_rich_texts_on_post_content", where: "(((record_type)::text = 'Post'::text) AND ((name)::text = 'content'::text))"
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "blog_exports", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_blog_exports_on_blog_id"
  end

  create_table "blogs", force: :cascade do |t|
    t.boolean "allow_search_indexing", default: true, null: false
    t.string "analytics_id"
    t.string "analytics_service"
    t.datetime "created_at", null: false
    t.string "custom_domain"
    t.string "delivery_email"
    t.datetime "discarded_at"
    t.boolean "email_subscriptions_enabled", default: true, null: false
    t.string "features", default: [], array: true
    t.string "fediverse_author_attribution"
    t.string "font", default: "sans", null: false
    t.string "google_site_verification"
    t.integer "layout", default: 0
    t.string "locale", default: "en", null: false
    t.boolean "reply_by_email", default: false, null: false
    t.boolean "show_branding", default: true, null: false
    t.boolean "show_upvotes", default: true, null: false
    t.string "subdomain", null: false
    t.string "theme", default: "base", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "width", default: "standard", null: false
    t.index ["custom_domain"], name: "index_blogs_on_custom_domain", unique: true, where: "(custom_domain IS NOT NULL)"
    t.index ["subdomain"], name: "index_blogs_on_subdomain", unique: true
    t.index ["user_id"], name: "index_blogs_on_user_id"
  end

  create_table "custom_domain_changes", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.string "custom_domain"
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_custom_domain_changes_on_blog_id"
  end

  create_table "digest_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_digest_id", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_digest_id"], name: "index_digest_posts_on_post_digest_id"
    t.index ["post_id"], name: "index_digest_posts_on_post_id"
  end

  create_table "email_change_requests", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "new_email", null: false
    t.string "token_digest"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_email_change_requests_on_expires_at"
    t.index ["token_digest"], name: "index_email_change_requests_on_token_digest", unique: true
    t.index ["user_id"], name: "index_email_change_requests_on_user_id"
  end

  create_table "email_subscribers", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id", "email"], name: "index_email_subscribers_on_blog_id_and_email", unique: true
  end

  create_table "open_graph_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["post_id"], name: "index_open_graph_images_on_post_id"
  end

  create_table "paddle_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "payload"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_paddle_events_on_user_id"
  end

  create_table "page_views", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_unique", default: false
    t.string "path"
    t.bigint "post_id"
    t.text "query_string"
    t.text "referrer"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.datetime "viewed_at", null: false
    t.string "visitor_hash", null: false
    t.index ["blog_id", "viewed_at"], name: "index_page_views_on_blog_id_and_viewed_at"
    t.index ["blog_id"], name: "index_page_views_on_blog_id"
    t.index ["post_id"], name: "index_page_views_on_post_id"
    t.index ["viewed_at"], name: "index_page_views_on_viewed_at"
    t.index ["visitor_hash", "post_id", "viewed_at"], name: "index_page_views_on_visitor_hash_and_post_id_and_viewed_at"
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.text "user"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pghero_space_stats", force: :cascade do |t|
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "relation"
    t.text "schema"
    t.bigint "size"
    t.index ["database", "captured_at"], name: "index_pghero_space_stats_on_database_and_captured_at"
  end

  create_table "post_digest_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.bigint "email_subscriber_id", null: false
    t.bigint "post_digest_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email_subscriber_id"], name: "index_post_digest_deliveries_on_email_subscriber_id"
    t.index ["post_digest_id"], name: "index_post_digest_deliveries_on_post_digest_id"
  end

  create_table "post_digests", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_post_digests_on_blog_id"
  end

  create_table "post_replies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "email_delivered", default: false, null: false
    t.text "message", null: false
    t.string "name", null: false
    t.bigint "post_id", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_post_replies_on_created_at"
    t.index ["email"], name: "index_post_replies_on_email"
    t.index ["post_id"], name: "index_post_replies_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.string "canonical_url"
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false, null: false
    t.boolean "is_page", default: false, null: false
    t.datetime "published_at"
    t.text "raw_content"
    t.boolean "show_in_navigation", default: true, null: false
    t.string "slug"
    t.integer "status", default: 1, null: false
    t.string "tag_list", default: [], array: true
    t.string "title"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "upvotes_count", default: 0, null: false
    t.index ["blog_id", "is_page"], name: "index_posts_on_blog_id_and_is_page"
    t.index ["blog_id", "slug"], name: "index_posts_on_blog_id_and_slug", unique: true
    t.index ["blog_id", "status", "published_at"], name: "index_posts_published_lookup", order: { published_at: :desc }, where: "(status = 1)"
    t.index ["blog_id", "status"], name: "index_posts_search_filter", where: "(status = ANY (ARRAY[0, 1]))"
    t.index ["blog_id"], name: "index_posts_on_blog_id_published_count_only", where: "((is_page = false) AND (status = 1))"
    t.index ["hidden"], name: "index_posts_on_hidden"
    t.index ["is_page"], name: "index_posts_on_is_page"
    t.index ["published_at"], name: "index_posts_on_published_at"
    t.index ["status"], name: "index_posts_on_status"
    t.index ["tag_list"], name: "index_posts_on_tag_list", using: :gin
    t.index ["title"], name: "index_posts_on_title_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["token"], name: "index_posts_on_token", unique: true
  end

  create_table "rollups", force: :cascade do |t|
    t.jsonb "dimensions", default: {}, null: false
    t.string "interval", null: false
    t.string "name", null: false
    t.datetime "time", null: false
    t.float "value"
    t.index ["name", "interval", "time", "dimensions"], name: "index_rollups_on_name_and_interval_and_time_and_dimensions", unique: true
  end

  create_table "sender_email_addresses", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at"
    t.string "token_digest"
    t.datetime "updated_at", null: false
    t.index ["blog_id", "email"], name: "index_sender_email_addresses_on_blog_id_and_email", unique: true
    t.index ["expires_at"], name: "index_sender_email_addresses_on_expires_at"
    t.index ["token_digest"], name: "index_sender_email_addresses_on_token_digest", unique: true
  end

  create_table "social_links", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.datetime "created_at", null: false
    t.string "platform", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["blog_id"], name: "index_social_links_on_blog_id"
  end

  create_table "subscription_renewal_reminders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "period", null: false
    t.datetime "sent_at", null: false
    t.bigint "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id", "period"], name: "idx_on_subscription_id_period_ee77f6799e", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.boolean "complimentary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "next_billed_at"
    t.string "paddle_customer_id"
    t.string "paddle_price_id"
    t.string "paddle_subscription_id"
    t.integer "unit_price"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["paddle_customer_id"], name: "index_subscriptions_on_paddle_customer_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "upvotes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hash_id", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "hash_id"], name: "index_upvotes_on_post_id_and_hash_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.boolean "marketing_consent", default: false, null: false
    t.string "onboarding_state", default: "account_created"
    t.string "timezone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "access_requests", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blog_exports", "blogs"
  add_foreign_key "blogs", "users"
  add_foreign_key "custom_domain_changes", "blogs"
  add_foreign_key "digest_posts", "post_digests"
  add_foreign_key "digest_posts", "posts"
  add_foreign_key "email_change_requests", "users"
  add_foreign_key "email_subscribers", "blogs"
  add_foreign_key "open_graph_images", "posts"
  add_foreign_key "paddle_events", "users"
  add_foreign_key "page_views", "blogs"
  add_foreign_key "page_views", "posts"
  add_foreign_key "post_digest_deliveries", "email_subscribers"
  add_foreign_key "post_digest_deliveries", "post_digests"
  add_foreign_key "post_digests", "blogs"
  add_foreign_key "post_replies", "posts"
  add_foreign_key "posts", "blogs"
  add_foreign_key "sender_email_addresses", "blogs"
  add_foreign_key "social_links", "blogs"
  add_foreign_key "subscription_renewal_reminders", "subscriptions"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "upvotes", "posts"
end
