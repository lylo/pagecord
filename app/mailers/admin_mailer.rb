class AdminMailer < ApplicationMailer
  def spam_detected_notification(user_id, reason)
    @user = User.find(user_id)
    @blog = @user.blog
    @reason = reason

    mail(
      to: "hello@pagecord.com",
      subject: "Spam Signup Detected: #{@blog.subdomain}"
    )
  end
end
