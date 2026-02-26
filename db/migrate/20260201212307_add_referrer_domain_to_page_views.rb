class AddReferrerDomainToPageViews < ActiveRecord::Migration[8.2]
  def change
    add_column :page_views, :referrer_domain, :string
    add_index :page_views, [ :blog_id, :referrer_domain, :viewed_at ], name: "index_page_views_on_blog_referrer_domain_viewed_at"
  end
end
