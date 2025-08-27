class CreatePageViews < ActiveRecord::Migration[8.1]
  def change
    create_table :page_views do |t|
      t.references :blog, null: false, foreign_key: true
      t.references :post, null: true, foreign_key: true  # null for index page views
      t.string :path, null: false
      t.string :visitor_hash, null: false
      t.string :ip_address
      t.text :user_agent
      t.text :referrer
      t.string :country
      t.boolean :is_unique, default: false
      t.datetime :viewed_at, null: false

      t.timestamps
    end

    add_index :page_views, [ :blog_id, :viewed_at ]
    add_index :page_views, [ :visitor_hash, :post_id, :viewed_at ]
    add_index :page_views, :viewed_at  # For cleanup job
  end
end
