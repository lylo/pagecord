class AddPageFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :is_page, :boolean, default: false, null: false
    add_column :posts, :show_in_navigation, :boolean, default: true, null: false

    add_index :posts, :is_page
    add_index :posts, [ :blog_id, :is_page ]
  end
end
