class AddIndexToPostsHidden < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, :hidden
  end
end
