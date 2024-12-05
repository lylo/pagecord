class Blog < ApplicationRecord
  include DeliveryEmail, CustomDomain

  belongs_to :user, inverse_of: :blog
  has_many :posts, dependent: :destroy

  has_many :followings, foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :followings, source: :follower

  has_rich_text :bio
  validate :bio_length

  def custom_title?
    title.present?
  end

  def username
    user.username
  end

  private

    def bio_length
      if bio.to_plain_text.length > 500
        errors.add(:bio, "is too long (maximum 500 characters)")
      end
    end
end
