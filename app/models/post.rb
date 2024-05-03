class Post < ApplicationRecord
  include OpaqueId

  belongs_to :user, inverse_of: nil

  has_rich_text :body
  has_many_attached :attachments

  before_create :set_published_at, :limit_body_size

  validate :body_or_title

  def body_or_title
    errors.add(:base, "Either body or title must be present") unless body.body.present? || title.present?
  end

  def open_graph_image
    if attachments.any?
      attachments.first
    end
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end

    def limit_body_size
      self.body = body.to_s.slice(0, 64.kilobytes)
    end
end
