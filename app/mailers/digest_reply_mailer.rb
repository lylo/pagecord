class DigestReplyMailer < PostmarkMailer
  include ActionView::Helpers::SanitizeHelper

  def forward_reply
    @digest = params[:digest]
    @blog = @digest.blog
    original_mail = params[:original_mail]

    return unless original_mail.from&.first

    sender = original_mail.from.first
    sender_name = original_mail[:from].display_names.first.presence || sender

    mail(
      to: @blog.user.email,
      from: "#{sender_name} <hello@notifications.pagecord.com>",
      reply_to: sender,
      subject: "Re: #{@digest.subject}",
      body: reply_text(original_mail),
      content_type: "text/plain"
    )
  end

  private

    # Replies are forwarded as plain text. Readers send arbitrary markup, and
    # relaying it would mean putting a stranger's HTML in the blog owner's inbox
    # along with cid references to attachments we don't forward.
    def reply_text(mail)
      if mail.multipart?
        mail.text_part&.body&.decoded || strip_tags(mail.html_part&.body&.decoded).to_s
      elsif mail.mime_type == "text/html"
        strip_tags(mail.body.decoded).to_s
      else
        mail.body.decoded
      end
    end
end
