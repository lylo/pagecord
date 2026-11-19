class Subscription::RenewalReminderMailerPreview < ActionMailer::Preview
  def reminder
    subscription = Subscription.active_paid.first
    Subscription::RenewalReminderMailer.reminder(subscription, subscription.unit_price)
  end
end
