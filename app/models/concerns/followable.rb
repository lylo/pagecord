module Followable
  extend ActiveSupport::Concern

  included do
    has_many :followings, foreign_key: :follower_id, dependent: :destroy
    has_many :followed_blogs, through: :followings, source: :followed
  end

  def follow(blog)
    if self.blog == blog
      raise ArgumentError, "You can't follow yourself"
    elsif following?(blog)
      raise ArgumentError, "#{self.username} is already following #{blog.id}"
    else
      followed_blogs << blog
    end
  end

  def unfollow(blog)
    if !following?(blog)
      raise ArgumentError, "#{username} is not following #{blog.id}"
    else
      followed_blogs.delete(blog)
    end
  end

  def following?(blog)
    followed_blogs.include?(blog)
  end
end
