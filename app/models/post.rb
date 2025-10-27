class Post < ApplicationRecord
  include Draftable, Sluggable, Tokenable, Trimmable, Upvotable, Taggable, Post::Searchable

  belongs_to :blog, inverse_of: nil

  has_rich_text :content
  has_many_attached :attachments, dependent: :destroy

  has_one :open_graph_image, as: :imageable, dependent: :destroy
  has_many :digest_posts, dependent: :destroy
  has_many :post_digests, through: :digest_posts
  has_many :replies, class_name: "Post::Reply", dependent: :destroy
  has_many :page_views, dependent: :destroy
  has_many :navigation_items, dependent: :destroy

  before_create :set_published_at, :limit_content_size
  before_save :set_text_summary

  validate :content_present
  validate :title_present_for_pages

  scope :posts, -> { where(is_page: false) }
  scope :pages, -> { where(is_page: true) }
  scope :navigation_pages, -> { pages.where(show_in_navigation: true) }
  scope :released, -> { where("published_at <= ?", Time.current) }
  scope :visible, -> { where.not(hidden: true).published.released }
  scope :with_full_rich_text, -> {
      with_rich_text_content_and_embeds.includes(
        :rich_text_content,
        rich_text_content: [
          :embeds_attachments,
          { embeds_attachments: { blob: :variant_records } }
        ]
      )
    }
  after_commit :generate_open_graph_image, on: [ :create, :update ]

  def content_present
    has_content = content.body.present? && content.body.to_plain_text.strip.present?
    has_attachments = content.body&.attachments&.any?

    unless has_content || has_attachments
      doc = Nokogiri::HTML::DocumentFragment.parse(content.body.to_s)
      unless doc.css("img, video, audio").any?
        errors.add(:content, "can't be blank")
      end
    end
  end

  attr_accessor :is_home_page

  def title_present_for_pages
    if page? && title.blank? && !home_page?
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
    return "" unless has_text_content?
    text_summary.truncate(limit, separator: /\s/)
  end

  def has_text_content?
    text_summary.present?
  end

  def display_title
    @display_title ||= if title.present?
      title.truncate(100).strip
    elsif home_page?
      "Home Page"
    elsif text_summary.present?
      text_summary.truncate(64, separator: /\s/)
    else
      "Untitled"
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

  def home_page?
    (blog.home_page_id.present? && blog.home_page_id == id) || is_home_page
  end

  def og_image_filename
    "og-preview-#{token}.png"
  end

  def should_generate_og_image?
    first_image.blank?
  end

  def first_image
    @first_image ||= begin
      if content_image_attachments.any?
        content_image_attachments.first
      elsif attachments.any?
        attachments.find(&:image?)
      end
    end
  end

  private

    def text_content
      doc = Nokogiri::HTML::DocumentFragment.parse(self.content.to_s)
      doc.css("figcaption").remove  # don't want captions in the summary

      # Add space after block-level elements to preserve paragraph boundaries
      doc.css("p, div, h1, h2, h3, h4, h5, h6, li, blockquote").each do |element|
        element.add_next_sibling(Nokogiri::XML::Text.new(" ", doc))
      end

      text_content = doc.text
      # Remove image references, [Image], URLs, and custom tags like {{ tag_name }}
      text_content.gsub(/\[.*?\.(jpg|png|gif|jpeg|webp)\]/i, "").strip
             .gsub(/\[Image\]/i, "").strip
             .gsub(/https?:\/\/\S+/, "").strip
             .gsub(/\{\{\s*(\w+)([^}]*)\}\}/, "").strip # strip tags
             .gsub(/\s+/, " ").strip  # Normalize whitespace
    end

    def set_text_summary
      self.text_summary = text_content.truncate(512, separator: /\s/, omission: "")
    end

    def set_published_at
      self.published_at ||= created_at
    end

    def limit_content_size
      if content && content.body.to_html.bytesize > 64.kilobytes
        self.content = content.body.to_html.byteslice(0, 64.kilobytes)
      end
    end

    def generate_open_graph_image
      # Skip in test mode unless explicitly enabled for performance
      return if Rails.env.test? && !@enable_open_graph_image_generation

      return if attachments.any? || content_image_attachments.any?
      return unless saved_change_to_title? || saved_change_to_text_summary?

      if Rails.env.production?
        GenerateOpenGraphImageJob.perform_later("Post", id)
      else
        GenerateOpenGraphImageJob.perform_now("Post", id)
      end
    end

    def content_image_attachments
      content.body.attachments.select { |attachment| attachment.try(:image?) }
    end
end
