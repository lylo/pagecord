class Blog < ApplicationRecord
  include Discard::Model
  include DeliveryEmail, CustomDomain, EmailSubscribable, Themeable, Localisable, CssSanitizable, Blog::CustomFooter, Blog::Contactable, Blog::ApiKey, Blog::RobotsTxt, Blog::Spotlit

  enum :layout, [ :stream_layout, :title_layout, :cards_layout ]

  belongs_to :user, inverse_of: :blogs

  MAX_BLOGS_FREE = 1
  MAX_BLOGS_PAID = 2

  AVATAR_CONTENT_TYPES = %w[ image/jpeg image/png image/webp ].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  has_many :all_posts, class_name: "Post", dependent: :destroy
  has_many :posts, -> { where(is_page: false) }, class_name: "Post"
  has_many :pages, -> { where(is_page: true) }, class_name: "Post"
  has_many :comments, -> { merge(Post.kept) }, through: :posts
  belongs_to :home_page, class_name: "Post", optional: true

  has_many :sender_email_addresses, dependent: :destroy

  has_many :navigation_items, dependent: :destroy
  has_many :social_navigation_items, -> { where(type: "SocialNavigationItem") }, class_name: "SocialNavigationItem", foreign_key: :blog_id

  has_many :exports, class_name: "Blog::Export", dependent: :destroy
  has_many :page_views, dependent: :destroy
  has_one :spam_detection, dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 96, 96 ], format: :png
  end

  has_rich_text :bio
  validate :bio_length, :bio_without_attachments
  validate :avatar_format
  validate :within_blog_limit, on: :create

  before_validation :downcase_subdomain
  after_commit :purge_cloudflare_cache, on: :update

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

  def host
    custom_domain.presence || "#{subdomain}.#{Rails.application.config.x.domain}"
  end

  # Perks of paying rather than things the blogger made, so the stored
  # preference only applies while the plan includes it. Replies are an ongoing
  # service – we mail the owner on their behalf – and branding removal
  # suppresses our own mark.
  def accepts_replies?
    reply_by_email && user.has_premium_access?
  end

  def branding_visible?
    !user.subscribed? || show_branding
  end

  def accepts_subscribers?
    email_subscriptions_enabled && user.subscribed?
  end

  def accepts_comments?
    comments_enabled && user.has_premium_access?
  end

  private

    def within_blog_limit
      if user && blog_count_exceeds_limit?
        errors.add(:base, "You can't add another blog because you've already reached your blog limit")
      end
    end

    def blog_count_exceeds_limit?
      if user.new_record? || user.association(:blogs).loaded?
        user.blogs.reject(&:marked_for_destruction?).size > user.blog_limit
      else
        user.blogs.count >= user.blog_limit
      end
    end

    def bio_length
      if bio.to_plain_text.length > 500
        errors.add(:bio, "is too long (maximum 500 characters)")
      end
    end

    # The bio editors don't offer attachments, so anything here arrived as
    # hand-crafted HTML.
    def bio_without_attachments
      errors.add(:bio, "can't contain attachments") if bio.body&.fragment&.find_all("action-text-attachment").present?
    end

    def avatar_format
      return unless avatar.attachment&.new_record?

      unless AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)
        errors.add(:avatar, "must be a JPEG, PNG or WebP image")
      end

      if avatar.blob.byte_size > AVATAR_MAX_SIZE
        errors.add(:avatar, "is too big (maximum 5MB)")
      end
    end

    def downcase_subdomain
      self.subdomain = self.subdomain.downcase.strip if self.subdomain.present?
    end

    def subdomain_valid
      unless Subdomain.valid_format?(subdomain)
        errors.add(:subdomain, "can only contain letters and numbers")
      end

      if subdomain_reserved?
        errors.add(:subdomain, "is reserved")
      end
    end

    def subdomain_reserved?
      (new_record? || will_save_change_to_subdomain?) && Subdomain.reserved?(subdomain)
    end

    def purge_cloudflare_cache
      return unless Rails.env.production?
      return unless Rails.cache.write("cf_purge:#{id}", true, expires_in: 5.seconds, unless_exist: true)
      # Trailing debounce: coalesce rapid updates (a bulk sync/import) into one
      # purge that fires after the burst, so the final state is never left stale.
      PurgeCloudflareCacheJob.set(wait: 5.seconds).perform_later(id)
    end
end
