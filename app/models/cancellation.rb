class Cancellation < ApplicationRecord
  REASONS = {
    too_expensive: "Too expensive",
    not_writing: "Not writing much any more",
    missing_feature: "Missing a feature I need",
    moving_platform: "Moving to another platform",
    something_else: "Something else"
  }.freeze

  belongs_to :user, optional: true

  enum :kind, { subscription: "subscription", account: "account" }
  enum :reason, REASONS.keys.index_with(&:to_s), validate: { allow_nil: true }

  validates :reason, presence: true
  validates :feedback, length: { maximum: 2000 }
end
