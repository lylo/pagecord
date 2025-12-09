class SenderEmailAddressMailer < ApplicationMailer
  def verify
    @sender_email_address = params[:sender_email_address]
    @blog = @sender_email_address.blog

    mail(
      to: @sender_email_address.email,
      subject: "Verify your sender email address for #{@blog.display_name}"
    )
  end
end
