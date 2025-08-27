class AllowNullPathInPageViews < ActiveRecord::Migration[8.1]
  def change
    change_column_null :page_views, :path, true
  end
end
