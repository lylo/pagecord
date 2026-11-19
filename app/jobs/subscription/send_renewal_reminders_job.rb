class Subscription::SendRenewalRemindersJob < ApplicationJob
  queue_as :default

  def perform
    subscriptions_renewing_in_two_weeks.find_each do |subscription|
      with_sentry_context(user: subscription.user, blog: subscription.user.blog) do
        period = Subscription::RenewalReminder.period_for(subscription.next_billed_at)

        next if subscription.renewal_reminders.exists?(period: period)

        charge = subscription.next_charge

        unless charge
          Rails.logger.warn "No renewal reminder for subscription #{subscription.id}: Paddle has no charge scheduled"
          next
        end

        subscription.transaction do
          subscription.update!(unit_price: charge)
          subscription.renewal_reminders.create!(period: period, sent_at: Time.current)
          Subscription::RenewalReminderMailer.reminder(subscription, charge).deliver_later
        end
      rescue => error
        Sentry.capture_exception(error)
      end
    end
  end

  private

    def subscriptions_renewing_in_two_weeks
      Subscription.active_paid.where.not(plan: :monthly).includes(user: :blogs).where("next_billed_at <= ?", 2.weeks.from_now)
    end
end
