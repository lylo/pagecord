class RemoveHtmlFlagFromPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :html, :boolean
  end
end
