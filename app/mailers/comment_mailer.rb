class CommentMailer < MailpaceMailer
  layout "mailer_minimal"

  def digest
    @blog = params[:blog]
    @comments = params[:comments]

    mail(
      to: @blog.user.email,
      subject: t("comments.mailer.subject")
    )
  end
end
