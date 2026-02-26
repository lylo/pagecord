class AddCountryToPageViews < ActiveRecord::Migration[8.2]
  def change
    add_column :page_views, :country, :string, limit: 2
    add_index :page_views, [ :blog_id, :country, :viewed_at ], name: "index_page_views_on_blog_country_viewed_at"
  end
end
