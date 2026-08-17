class ContactMailer < MailpaceMailer
  layout "mailer_minimal"
  helper :routing

  def new_message
    @contact_message = params[:contact_message]
    @blog = @contact_message.blog

    I18n.with_locale(@blog.locale) do
      mail(
        to: @blog.user.email,
        subject: t("contact_form.mailer.subject", name: @contact_message.name),
        reply_to: @contact_message.email
      )
    end
  end
end
