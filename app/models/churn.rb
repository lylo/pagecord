# A departure, kept forever. Deliberately has no inverse association on User and no
# foreign key, so it survives accounts:purge_cancellations destroying the account it
# describes. Everything worth knowing is denormalised here at write time.
class Churn < ApplicationRecord
  belongs_to :user, optional: true

  enum :kind, { subscription_cancelled: "subscription_cancelled", account_deleted: "account_deleted" }

  # Idempotent: an in-app cancellation and the Paddle webhook that follows it describe
  # one churn, so the second caller finds the row the first one wrote.
  def self.record(user, kind, occurred_at: Time.current)
    subscription = user.subscription
    blog = user.blog

    find_or_create_by(user_id: user.id, kind: kind, paddle_subscription_id: subscription&.paddle_subscription_id) do |churn|
      churn.occurred_at = occurred_at
      churn.plan = subscription&.plan
      churn.unit_price = subscription&.unit_price
      churn.subscribed_at = subscription&.created_at
      churn.signed_up_at = user.created_at
      churn.signup_referrer = user.signup_referrer
      churn.blog_subdomain = blog&.subdomain
      churn.posts_count = blog&.posts&.count
    end
  rescue ActiveRecord::RecordNotUnique
    # Those two can also land together, in which case the unique index settles which
    # one wrote the row.
    find_by(kind: kind, paddle_subscription_id: subscription&.paddle_subscription_id)
  end

  # Only cancellations carry revenue. Deleted accounts keep their plan as context, so
  # counting both would double up.
  def self.mrr_lost(churns)
    churns.select(&:subscription_cancelled?).sum(&:monthly_unit_price) / 100.0
  end

  # Normalised the way the mrr_cents rollup is, so one annual cancellation doesn't
  # dwarf ten monthly ones.
  def monthly_unit_price
    return 0 if unit_price.blank?

    plan == "monthly" ? unit_price : unit_price / 12.0
  end

  # Paid tenure where we have it, account tenure otherwise. For a free departure the
  # signup date is the only clock we get.
  def tenure_in_months
    started = subscribed_at || signed_up_at
    return unless started

    months = (occurred_at.year - started.year) * 12 + occurred_at.month - started.month
    occurred_at.day < started.day ? months - 1 : months
  end
end
