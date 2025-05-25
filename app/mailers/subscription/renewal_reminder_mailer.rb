class Subscription::RenewalReminderMailer < MailpaceMailer
  def reminder(subscription)
    @subscription = subscription
    @user = subscription.user
    @renewal_date = subscription.next_billed_at.to_date
    @price = Subscription.price

    mail(
      to: @user.email,
      subject: "Your Pagecord subscription renews soon"
    )
  end
end
