class ReplyMailer < ResendMailer
  helper :routing

  def new_reply
    @reply = params[:reply]
    @post = @reply.post
    @blog = @post.blog

    subject = "Re: #{@post.display_title}"

    mail(
      to: @blog.user.email,
      subject: subject,
      reply_to: @reply.email
    )
  end
end
