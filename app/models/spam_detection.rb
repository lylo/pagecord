class SpamDetection < ApplicationRecord
  belongs_to :blog

  enum :status, { clean: 0, spam: 1, uncertain: 2, error: 3, skipped: 4 }

  scope :needs_review, -> { where(status: [ :spam, :uncertain ]).where(reviewed: false) }
  scope :recent, -> { order(detected_at: :desc) }
  scope :today, -> { where("detected_at >= ?", Time.current.beginning_of_day) }

  def mark_as_reviewed!
    update!(reviewed: true, reviewed_at: Time.current)
  end

  def needs_review?
    (spam? || uncertain?) && !reviewed?
  end
end
