class WelcomeMailer < MailpaceMailer
  helper :routing

  def welcome_email
    @user = params[:user]
    @blog = @user.blog
    @price = params[:price] || Subscription.price

    mail(
      to: @user.email,
      subject: "Welcome to Pagecord!"
    )
  end
end
