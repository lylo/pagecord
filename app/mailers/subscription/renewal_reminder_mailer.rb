class Subscription::RenewalReminderMailer < CloudflareMailer
  helper :routing, :subscriptions

  def reminder(subscription, charge)
    @subscription = subscription
    @charge = charge
    @user = subscription.user
    @blog = @user.blog
    @renewal_date = subscription.next_billed_at.to_date

    mail(
      to: @user.email,
      subject: "Your Pagecord subscription renews soon"
    )
  end
end
