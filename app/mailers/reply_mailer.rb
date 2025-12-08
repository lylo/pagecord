class ReplyMailer < MailpaceMailer
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
    ).tap { |m| use_resend(m) if Rails.features.for(blog: @blog).enabled?(:resend) }
  end

  private

    def use_resend(message)
      return unless Rails.env.production?
      message.delivery_method(:resend)
      message.from = "Pagecord <no-reply@remailer.pagecord.com>"
    end
end
