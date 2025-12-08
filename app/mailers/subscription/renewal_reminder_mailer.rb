class Subscription::RenewalReminderMailer < ResendMailer
  def reminder(subscription)
    @subscription = subscription
    @user = subscription.user
    @renewal_date = subscription.next_billed_at.to_date
    @price = @subscription.unit_price / 100

    mail(
      to: @user.email,
      subject: "Your Pagecord subscription renews soon"
    )
  end
end
