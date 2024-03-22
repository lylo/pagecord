class RemoveDefaultFromHtmlInPosts < ActiveRecord::Migration[7.2]
  def change
    change_column_default :posts, :html, nil
  end
end
