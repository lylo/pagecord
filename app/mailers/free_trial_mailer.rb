class FreeTrialMailer < MailpaceMailer
  helper :routing

  default from: "Olly at Pagecord <hello@mailer.pagecord.com>",
          reply_to: "Olly at Pagecord <olly@pagecord.com>"

  def trial_ended
    @user = params[:user]
    @blog = @user.blog
    @price = Subscription.price
    @monthly_price = Subscription.price(:monthly)
    @monthly_enabled = ENV["MONTHLY_ENABLED"] == "true"

    mail to: @user.email, subject: "Your Pagecord free trial has ended"
  end
end
