class WelcomeMailer < MailpaceMailer
  helper :routing

  default from: "Olly at Pagecord <hello@mailer.pagecord.com>",
          reply_to: "Olly at Pagecord <olly@pagecord.com>"

  # Sent immediately after a user completes signup (via AccessRequestsController).
  def welcome_email
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "Pick a theme, add a Home or About page, then publish your first post."

    mail to: @user.email, subject: "Your Pagecord is live! Time to make it your own"
  end

  # Sent to users who signed up 1+ month ago but never completed onboarding
  # (still in "account_created" state). Triggered by SendUnengagedFollowUpEmailsJob.
  def onboarding_follow_up
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "It only takes a minute to make your blog feel like yours."

    mail to: @user.email, subject: "Your Pagecord is waiting — make it yours"
  end

  # Sent to users who completed onboarding 1+ month ago but never published a post.
  # Triggered by SendUnengagedFollowUpEmailsJob.
  def no_content_follow_up
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "Don't overthink it — an About page, a short post, anything at all."

    mail to: @user.email, subject: "Your Pagecord could use a first post"
  end
end
