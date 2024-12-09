class AddUpvoteCountToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :upvotes_count, :integer, default: 0, null: false

    Post.find_each do |post|
      post.update_column(:upvotes_count, post.upvotes.count)
    end
  end
end
