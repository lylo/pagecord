class Post < ApplicationRecord
  include OpaqueId

  belongs_to :user

  before_create :set_published_at

  validate :content_or_title

  def content_or_title
    errors.add(:base, "Either content or title must be present") unless content.present? || title.present?
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end
end
