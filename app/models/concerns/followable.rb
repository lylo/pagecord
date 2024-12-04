module Followable
  extend ActiveSupport::Concern

  included do
    has_many :followed_users, foreign_key: :follower_id, class_name: "Following", dependent: :destroy
    has_many :followees, through: :followed_users, source: :followed

    has_many :following_blogs, foreign_key: :followed_id, class_name: "Following", dependent: :destroy
    has_many :followers, through: :following_blogs, source: :follower
  end

  def follow(blog)
    if self.blog == blog
      raise ArgumentError, "You can't follow yourself"
    elsif following?(blog)
      raise ArgumentError, "#{self.username} is already following #{blog.id}"
    else
      followees << blog
    end
  end

  def unfollow(blog)
    if !following?(blog)
      raise ArgumentError, "#{username} is not following #{blog.id}"
    else
      followees.delete(blog)
    end
  end

  def following?(blog)
    followees.include?(blog)
  end
end
