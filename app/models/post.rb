class Post < ApplicationRecord
  include OpaqueId, Trimmable

  belongs_to :user, inverse_of: nil

  has_one :open_graph_image, dependent: :destroy
  has_rich_text :content
  has_many_attached :attachments, dependent: :destroy

  before_create :set_published_at, :limit_content_size
  after_create  :detect_open_graph_image

  validate :body_or_title

  def body_or_title
    errors.add(:base, "Either body or title must be present") unless content.body.present? || title.present?
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
        GenerateOpenGraphImageJob.perform_later(self)
      else
        GenerateOpenGraphImageJob.perform_now(self)
      end
    end
end
