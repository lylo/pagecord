class Post < ApplicationRecord
  include Draftable, Sluggable, Tokenable, Trimmable, Upvotable

  belongs_to :blog, inverse_of: nil

  has_rich_text :content
  has_many_attached :attachments, dependent: :destroy

  has_one :open_graph_image, dependent: :destroy
  has_many :digest_posts, dependent: :destroy
  has_many :post_digests, through: :digest_posts
  has_many :replies, class_name: "Post::Reply", dependent: :destroy

  before_create :set_published_at, :limit_content_size

  validate :content_present
  validate :title_present_for_pages

  scope :posts, -> { where(is_page: false) }
  scope :pages, -> { where(is_page: true) }
  scope :navigation_pages, -> { pages.where(show_in_navigation: true) }
  scope :visible, -> { published.where("published_at <= ?", Time.current) }

  after_create :detect_open_graph_image

  def content_present
    errors.add(:content, "can't be blank") unless content.body.present?
  end

  def title_present_for_pages
    if page? && title.blank?
      errors.add(:title, "can't be blank")
    end
  end

  def to_param
    token
  end

  def pending?
    published_at > Time.current
  end

  def summary(limit: 64)
    summary = self.content.to_plain_text
      .gsub(/\[.*?\.(jpg|png|gif|jpeg|webp)\]/i, "").strip
      .gsub(/\[Image\]/i, "").strip
      .gsub(/https?:\/\/\S+/, "").strip
      .truncate(limit, separator: /\s/)

    summary.presence || "Untitled"
  end

  def display_title
    if title.present?
      title.truncate(100).strip
    else
      summary
    end
  end

  def timezone
    blog.user.timezone
  end

  def published_at_in_user_timezone
    published_at.in_time_zone(timezone)
  end

  def page?
    is_page
  end

  def post?
    !is_page
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end

    def limit_content_size
      self.content = content.to_s.slice(0, 64.kilobytes)
    end

    def detect_open_graph_image
      if Rails.env.production?
        GenerateOpenGraphImageJob.perform_later(id)
      else
        GenerateOpenGraphImageJob.perform_now(id)
      end
    end
end
