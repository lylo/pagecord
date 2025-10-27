class Blog < ApplicationRecord
  include DeliveryEmail, CustomDomain, EmailSubscribable, Themeable, Localisable, CssSanitizable

  enum :layout, [ :stream_layout, :title_layout, :cards_layout ]

  belongs_to :user, inverse_of: :blog

  has_many :all_posts, class_name: "Post", dependent: :destroy
  has_many :posts, -> { where(is_page: false) }, class_name: "Post"
  has_many :pages, -> { where(is_page: true) }, class_name: "Post"
  belongs_to :home_page, class_name: "Post", optional: true

  has_many :sender_email_addresses, dependent: :destroy

  has_many :navigation_items, dependent: :destroy
  has_many :social_navigation_items, -> { where(type: "SocialNavigationItem") }, class_name: "SocialNavigationItem", foreign_key: :blog_id

  has_many :followings, foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :followings, source: :follower

  has_many :exports, class_name: "Blog::Export", dependent: :destroy
  has_many :page_views, dependent: :destroy

  has_one :open_graph_image, as: :imageable, dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 300, 300 ]
  end

  has_rich_text :bio
  validate :bio_length

  before_validation :downcase_subdomain
  after_commit :generate_default_og_image, on: [:create, :update], if: -> { saved_change_to_subdomain? || saved_change_to_title? || saved_change_to_theme? }

  validates :subdomain, presence: true, uniqueness: true, length: { minimum: Subdomain::MIN_LENGTH, maximum: Subdomain::MAX_LENGTH }
  validate  :subdomain_valid
  validates :google_site_verification, format: { with: /\A[a-zA-Z0-9_-]+\z/, message: "can only contain letters, numbers, underscores, and hyphens" }, allow_blank: true

  def has_custom_home_page?
    home_page.present?
  end

  def custom_title?
    title.present?
  end

  def display_name
    title.blank? ? "@#{subdomain}" : title
  end

  def og_image_filename
    "og-blog-#{subdomain}.png"
  end

  def should_generate_og_image?
    true
  end

  private

    def bio_length
      if bio.to_plain_text.length > 500
        errors.add(:bio, "is too long (maximum 500 characters)")
      end
    end

    def downcase_subdomain
      self.subdomain = self.subdomain.downcase.strip if self.subdomain.present?
    end

    def subdomain_valid
      unless Subdomain.valid_format?(subdomain)
        errors.add(:subdomain, "can only use letters, numbers or underscores")
      end

      if Subdomain.reserved?(subdomain)
        errors.add(:subdomain, "is reserved")
      end
    end

    def generate_default_og_image
      return if Rails.env.test? && !@enable_open_graph_image_generation

      if Rails.env.production?
        GenerateOpenGraphImageJob.perform_later("Blog", id)
      else
        GenerateOpenGraphImageJob.perform_now("Blog", id)
      end
    end
end
