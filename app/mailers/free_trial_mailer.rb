class FreeTrialMailer < CloudflareMailer
  helper :routing

  default from: "Olly at Pagecord <hello@cfmail.pagecord.com>",
          reply_to: "Olly at Pagecord <olly@pagecord.com>"

  def trial_ended
    @user = params[:user]
    @blog = @user.blog

    mail to: @user.email, subject: "Your Pagecord free trial has ended"
  end

  def trial_reminder
    @user = params[:user]
    @blog = @user.blog
    @ends_on = @user.trial_ends_at.strftime("%A %-d %B")

    mail to: @user.email, subject: "Your Pagecord free trial ends on #{@ends_on}"
  end
end
