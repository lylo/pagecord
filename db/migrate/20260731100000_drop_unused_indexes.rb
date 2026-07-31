class DropUnusedIndexes < ActiveRecord::Migration[8.2]
  disable_ddl_transaction!

  def change
    # Zero scans since stats were last reset. (blog_id, viewed_at) covers the
    # same prefix and is what the planner already picks for the countries query,
    # so there's a working fallback. page_views takes a row per request, so this
    # is one less index entry on the hottest write path in the app.
    remove_index :page_views, [ :blog_id, :country, :viewed_at ],
      name: "index_page_views_on_blog_country_viewed_at",
      algorithm: :concurrently, if_exists: true

    # Nothing looks a user up by bcrypt hash, and nothing could.
    remove_index :users, :password_digest, name: "index_users_on_password_digest",
      algorithm: :concurrently, if_exists: true
  end
end
