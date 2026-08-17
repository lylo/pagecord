class CommentMailer < MailpaceMailer
  layout "mailer_minimal"

  def digest
    @blog = params[:blog]
    @comments = params[:comments]

    I18n.with_locale(@blog.locale) do
      mail(
        to: @blog.user.email,
        subject: t("comments.mailer.subject")
      )
    end
  end
end
