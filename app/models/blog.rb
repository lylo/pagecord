class Blog < ApplicationRecord
  include DeliveryEmail, CustomDomain

  belongs_to :user, inverse_of: :blog
  has_many :posts, dependent: :destroy

  has_many :followings, foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :followings, source: :follower

  has_rich_text :bio
  validate :bio_length

  before_validation :downcase_name

  validates :name, presence: true, uniqueness: true, length: { minimum: Username::MIN_LENGTH, maximum: Username::MAX_LENGTH }
  validate  :name_valid

  def custom_title?
    title.present?
  end

  private

    def bio_length
      if bio.to_plain_text.length > 500
        errors.add(:bio, "is too long (maximum 500 characters)")
      end
    end

    def downcase_name
      self.name = self.name.downcase.strip if self.name.present?
    end

    def name_valid
      unless Username.valid_format?(name)
        errors.add(:name, "must only use alphanumeric characters, full stops (periods) or underscores")
      end
    end
end