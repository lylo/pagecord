module Followable
  extend ActiveSupport::Concern

  included do
    has_many :followed_users, foreign_key: :follower_id, class_name: "Following", dependent: :destroy
    has_many :followees, through: :followed_users, source: :followed

    has_many :following_users, foreign_key: :followed_id, class_name: "Following", dependent: :destroy
    has_many :followers, through: :following_users, source: :follower
  end

  def follow(user)
    if self == user
      raise ArgumentError, "You can't follow yourself"
    elsif following?(user)
      raise ArgumentError, "#{self.username} is already following #{user.username}"
    else
      followees << user
    end
  end

  def unfollow(user)
    if !following?(user)
      raise ArgumentError, "#{self.username} is not following #{user.username}"
    else
      followees.delete(user)
    end
  end

  def following?(user)
    followees.include?(user)
  end

  def is_followed_by?(user)
    followers.include?(user)
  end
end
