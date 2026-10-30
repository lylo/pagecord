class AddShowPostNavigationToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :show_post_navigation, :boolean, default: false, null: false
  end
end
