class Post < ApplicationRecord
  include OpaqueId

  belongs_to :user

  before_create :set_published_at, :limit_content_size

  validate :content_or_title

  def content_or_title
    errors.add(:base, "Either content or title must be present") unless content.present? || title.present?
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end

    def limit_content_size
      self.content = content.slice(0, 64.kilobytes)
    end
end
