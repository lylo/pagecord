class Subscription::SupporterWelcomeMailer < CloudflareMailer
  helper :routing

  def welcome(subscription)
    @subscription = subscription
    @user = subscription.user
    @blog = @user.blog

    mail(
      to: @user.email,
      subject: "Thank you for becoming a Pagecord Supporter 💛"
    )
  end
end
