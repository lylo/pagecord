class DigestReplyMailer < ApplicationMailer
  def forward_reply
    @digest = params[:digest]
    @blog = @digest.blog
    @original_mail = params[:original_mail]

    return unless @original_mail.from&.first

    # Forward the original email verbatim with "Re:" to the digest subject
    mail(
      to: @blog.user.email,
      from: @original_mail.from.first,
      subject: "Re: #{@digest.subject}",
      body: @original_mail.body.to_s,
      content_type: @original_mail.content_type
    )
  end
end