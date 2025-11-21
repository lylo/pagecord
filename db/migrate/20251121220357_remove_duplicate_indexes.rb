class RemoveDuplicateIndexes < ActiveRecord::Migration[8.2]
  def change
    remove_index :navigation_items, name: :index_navigation_items_on_blog_id, if_exists: true
    remove_index :page_views, name: :index_page_views_on_blog_id, if_exists: true
  end
end
