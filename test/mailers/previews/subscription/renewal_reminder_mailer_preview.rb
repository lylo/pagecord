class Subscription::RenewalReminderMailerPreview < ActionMailer::Preview
  def reminder
    subscription = Subscription.active_paid.first
    Subscription::RenewalReminderMailer.reminder(subscription)
  end
end
