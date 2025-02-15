class Subscription::SendRenewalRemindersJob < ApplicationJob
  queue_as :default

  def perform
    subscriptions_renewing_in_two_weeks.find_each do |subscription|
      period = Subscription::RenewalReminder.period_for(subscription.next_billed_at)

      next if subscription.renewal_reminders.exists?(period: period)

      subscription.transaction do
        subscription.renewal_reminders.create!(
          period: period,
          sent_at: Time.current
        )
        Subscription::RenewalReminderMailer.reminder(subscription).deliver_later
      end
    end
  end

  private

    def subscriptions_renewing_in_two_weeks
      Subscription.active_paid
          .where("next_billed_at <= ?", 2.weeks.from_now)
    end
end
