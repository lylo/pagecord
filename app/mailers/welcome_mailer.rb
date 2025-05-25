class WelcomeMailer < MailpaceMailer
  helper :routing

  def welcome_email
    @user = params[:user]
    @blog = @user.blog

    mail(
      to: @user.email,
      subject: "Welcome to Pagecord!"
    )
  end
end
