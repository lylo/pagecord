class ReplyMailer < ApplicationMailer
  include ApplicationHelper

  helper :application

  def new_reply
    @reply = params[:reply]
    @post = @reply.post

    subject = "New reply to your post: #{post_title(@post)}"

    mail(
      to: @post.blog.user.email,
      subject: subject,
      reply_to: @reply.email
    )
  end
end
