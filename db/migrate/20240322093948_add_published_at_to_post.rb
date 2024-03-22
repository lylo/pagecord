class AddPublishedAtToPost < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :published_at, :datetime

    Post.find_each do |post|
      post.update_column :published_at, post.created_at
    end
  end
end
