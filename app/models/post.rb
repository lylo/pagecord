class Post < ApplicationRecord
  include Draftable, Tokenable, Trimmable, Upvotable

  belongs_to :blog, inverse_of: nil

  has_one :open_graph_image, dependent: :destroy
  has_rich_text :content
  has_many_attached :attachments, dependent: :destroy

  has_many :digest_posts, dependent: :destroy
  has_many :post_digests, through: :digest_posts

  before_create :set_published_at, :limit_content_size, :check_title_and_content
  after_create  :detect_open_graph_image

  validate :body_or_title

  scope :visible, -> { published.where("published_at <= ?", Time.current) }

  def body_or_title
    errors.add(:base, "A body or a title must be present") unless content.body.present? || title.present?
  end

  def to_param
    token
  end

  def to_title_param
    if url_title.blank?
      token
    else
      "#{url_title}-#{token}"
    end
  end

  def url_title
    title&.parameterize&.truncate(72, omission: "") || ""
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

    def check_title_and_content
      if title.present? && content.body.blank?
        self.content.body = title
        self.title = nil
      end
    end
end
