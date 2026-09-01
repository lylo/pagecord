# What survives when a discarded user is purged.
class AccountTombstone < ApplicationRecord
  enum :reason, {
    user_deleted: "user_deleted",
    spam: "spam",
    admin_deleted: "admin_deleted"
  }

  def self.record!(user, reason:)
    create!(
      user_id: user.id,
      signed_up_at: user.created_at,
      deleted_at: Time.current,
      reason: reason,
      plan: user.subscription&.plan,
      subdomain: (user.blogs.pluck(:subdomain).join(" ").presence if reason.to_s == "spam")
    )
  end
end
