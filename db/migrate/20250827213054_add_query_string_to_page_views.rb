class AddQueryStringToPageViews < ActiveRecord::Migration[8.1]
  def change
    add_column :page_views, :query_string, :text
  end
end
