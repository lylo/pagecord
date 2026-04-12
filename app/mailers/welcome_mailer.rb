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
    @preheader_text = "Start with a theme, an About page, or a short first post."

    mail to: @user.email, subject: "Need a hand setting up your Pagecord?"
  end

  # Sent to users who completed onboarding 1+ month ago but never published a post.
  # Triggered by SendUnengagedFollowUpEmailsJob.
  def no_content_follow_up
    @user = params[:user]
    @blog = @user.blog
    @preheader_text = "Create a Home or About page, or publish your first post to get started!"

    mail to: @user.email, subject: "Your Pagecord is ready. Time to create a page or publish a post!"
  end
end
