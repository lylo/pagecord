class ContentModeration < ApplicationRecord
  belongs_to :post

  enum :status, { pending: 0, clean: 1, flagged: 2, error: 3 }

  scope :needs_review, -> { where(status: [ :pending, :error ]) }

  def flagged_categories
    flags.select { |_category, flagged| flagged }.keys
  end

  def has_flagged_content?
    flags.values.any?
  end
end
