class Post < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper
  include OpaqueId

  belongs_to :user

  before_create :set_published_at
  before_save :format_content

  validate :content_or_title

  def content_or_title
    errors.add(:base, "Either content or title must be present") unless content.present? || title.present?
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end

    def format_content
      if strip_tags(content).blank?
        self.content = title
        self.title = nil
      end
    end
end
