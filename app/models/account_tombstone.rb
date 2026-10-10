# What survives when a discarded user is purged.
class AccountTombstone < ApplicationRecord
  belongs_to :user, optional: true

  enum :reason, {
    user_deleted: "user_deleted",
    spam: "spam",
    admin_deleted: "admin_deleted"
  }

  def self.record!(user, reason:)
    spam = reason.to_s == "spam"

    create!(
      user_id: user.id,
      signed_up_at: user.created_at,
      deleted_at: Time.current,
      reason: reason,
      plan: user.subscription&.plan,
      subdomain: (user.blogs.pluck(:subdomain).join(" ").presence if spam),
      failed_checks: (user.screening&.failed_checks if spam)
    )
  end
end
