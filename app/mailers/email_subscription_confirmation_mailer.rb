class EmailSubscriptionConfirmationMailer < MailpaceMailer
  layout "mailer_digest"
  helper RoutingHelper

  def confirm
    @subscriber = params[:subscriber]

    I18n.with_locale(@subscriber.blog.locale) do
      mail(to: @subscriber.email, subject: I18n.t("email_subscribers.mailers.confirmation.subject", blog_name: @subscriber.blog.display_name))
    end
  end
end
