class MigrateFollowees < ActiveRecord::Migration[8.1]
  def change
    Following.find_each do |following|
      # followed_id is now the blog id
      if user = User.find(following.followed_id)
        following.followed_id = user.blog.id
        following.save!
      end
    end
  end
end
