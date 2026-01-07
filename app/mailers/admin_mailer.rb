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

  def content_flagged_notification(post_id)
    @post = Post.find(post_id)
    @blog = @post.blog

    mail(
      to: "hello@pagecord.com",
      subject: "Content Flagged: #{@blog.subdomain} - #{@post.display_title.truncate(50)}"
    )
  end
end
