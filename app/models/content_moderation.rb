class ContentModeration < ApplicationRecord
  belongs_to :post

  enum :status, { pending: 0, clean: 1, flagged: 2, error: 3 }

  scope :needs_review, -> { where(status: [ :pending, :error ]) }

  def flagged_categories
    flags.select { |_, v| v == true }.keys
  end

  def has_flagged_content?
    flags.values.any? { |v| v == true }
  end
end
