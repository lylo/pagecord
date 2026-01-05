class AdminMailer < ApplicationMailer
  def spam_detected_notification(user_id, classification, reason)
    @user = User.find(user_id)
    @blog = @user.blog
    @classification = classification
    @reason = reason

    mail(
      to: "hello@pagecord.com",
      subject: "Spam Detection [#{classification}]: #{@blog.subdomain}"
    )
  end
end
