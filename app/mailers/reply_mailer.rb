class ReplyMailer < MailpaceMailer
  layout "mailer_minimal"
  helper :routing

  def new_reply
    @reply = params[:reply]
    @post = @reply.post
    @blog = @post.blog

    I18n.with_locale(@blog.locale) do
      mail(
        to: @blog.user.email,
        subject: "Re: #{@post.display_title}",
        reply_to: @reply.email
      )
    end
  end
end
