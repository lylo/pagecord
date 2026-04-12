class WelcomeMailer < MailpaceMailer
  helper :routing

  default from: "Olly at Pagecord <hello@mailer.pagecord.com>",
          reply_to: "Olly at Pagecord <olly@pagecord.com>"

  def welcome_email
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "Pick a theme, add a home/About/Now page, and publish your first post."

    mail to: @user.email, subject: "Your Pagecord is live. Make it yours."
  end

  def onboarding_follow_up
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "Start with a theme, an About page, or a short first post."

    mail to: @user.email, subject: "Need a hand setting up your Pagecord?"
  end

  def no_content_follow_up
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "Create an About or Now page, or publish one short post to get going."

    mail to: @user.email, subject: "Your Pagecord is ready for its first page or post"
  end
end
