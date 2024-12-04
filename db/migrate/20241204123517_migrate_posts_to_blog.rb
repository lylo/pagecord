class MigratePostsToBlog < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :blog, foreign_key: true

    Post.find_each do |post|
      post.blog = post.user.blog
      post.save!
    end

    change_column_null :posts, :blog_id, false
  end
end
