class RemoveShowInNavigationFromPosts < ActiveRecord::Migration[8.2]
  def change
    remove_column :posts, :show_in_navigation, :boolean, default: true, null: false
  end
end
