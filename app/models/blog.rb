class Blog < ApplicationRecord
  include DeliveryEmail, CustomDomain, EmailSubscribable, Themeable

  enum :layout, [ :stream_layout, :title_layout ]

  belongs_to :user, inverse_of: :blog
  has_many :posts, dependent: :destroy
  has_many :social_links, dependent: :destroy
  accepts_nested_attributes_for :social_links, allow_destroy: true

  has_many :followings, foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :followings, source: :follower

  has_many :exports, class_name: "Blog::Export", dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 300, 300 ]
  end

  has_rich_text :bio
  validate :bio_length

  before_validation :downcase_name

  validates :name, presence: true, uniqueness: true, length: { minimum: Username::MIN_LENGTH, maximum: Username::MAX_LENGTH }
  validate  :name_valid

  def custom_title?
    title.present?
  end

  def display_name
    title.blank? ? "@#{name}" : title
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
        errors.add(:name, "Username can only use letters, numbers or underscores")
      end
    end
end
