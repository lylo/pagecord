class DigestReplyMailer < ApplicationMailer
  def forward_reply
    @digest = params[:digest]
    @blog = @digest.blog
    @original_mail = params[:original_mail]

    return unless @original_mail.from&.first

    mail(
      to: @blog.user.email,
      reply_to: @original_mail.from.first,
      subject: "Re: #{@digest.subject}"
    ) do |format|
      if @original_mail.multipart?
        # Forward both text and html parts
        text_part = @original_mail.text_part
        html_part = @original_mail.html_part

        format.text { render plain: text_part.body.decoded } if text_part
        format.html { render html: html_part.body.decoded.html_safe } if html_part
      else
        # Single part (plain or html)
        if @original_mail.content_type =~ /html/
          format.html { render html: @original_mail.body.decoded.html_safe }
        else
          format.text { render plain: @original_mail.body.decoded }
        end
      end

      # Forward only inline attachments
      @original_mail.attachments.select { |a| a.inline? }.each do |attachment|
        attachments[attachment.filename] = {
          mime_type: attachment.mime_type,
          content: attachment.body.decoded,
          content_id: attachment.cid
        }
      end
    end
  end
end
