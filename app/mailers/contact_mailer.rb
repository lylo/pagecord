class ContactMailer < MailpaceMailer
  helper :routing

  def new_message
    @contact_message = params[:contact_message]
    @blog = @contact_message.blog

    mail(
      to: @blog.user.email,
      subject: I18n.t("contact_form.mailer.subject", name: @contact_message.name),
      reply_to: @contact_message.email
    )
  end
end
