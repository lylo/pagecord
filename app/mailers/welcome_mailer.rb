class WelcomeMailer < MailpaceMailer
  helper :routing

  def welcome_email
    @user = params[:user]
    @blog = @user.blog
    @price = params[:price] || Subscription.price

    mail(
      from: "Olly at Pagecord <no-reply@mailer.pagecord.com>",
      reply_to: "Olly at Pagecord <hello@pagecord.com>",
      to: @user.email,
      subject: "Welcome to Pagecord!"
    )
  end
end
