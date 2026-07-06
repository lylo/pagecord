class AvatarModeration < ApplicationRecord
  belongs_to :blog

  enum :status, { clean: 0, flagged: 1, error: 2 }

  scope :needs_review, -> { where(status: :flagged, reviewed_at: nil) }

  def flagged_categories
    flags.select { |_category, flagged| flagged }.keys
  end

  def mark_as_reviewed!
    update!(reviewed_at: Time.current)
  end

  def reviewed?
    reviewed_at.present?
  end
end
