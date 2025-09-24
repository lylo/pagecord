class ReplyMailer < MailpaceMailer
  helper :routing

  def new_reply
    @reply = params[:reply]
    @post = @reply.post

    subject = "Re: #{@post.display_title}"

    mail(
      to: @post.blog.user.email,
      subject: subject,
      reply_to: @reply.email
    )
  end
end
