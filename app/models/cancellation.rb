class Cancellation < ApplicationRecord
  belongs_to :user, optional: true

  enum :kind, { subscription: "subscription", account: "account" }
  enum :reason, {
    too_expensive: "too_expensive",
    not_writing: "not_writing",
    missing_feature: "missing_feature",
    moving_platform: "moving_platform",
    something_else: "something_else"
  }, validate: true
end
