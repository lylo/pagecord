class EmailSubscriptionConfirmationMailer < MailpaceMailer
  layout "mailer_minimal"
  helper RoutingHelper

  def confirm
    @subscriber = params[:subscriber]
    @blog = @subscriber.blog

    I18n.with_locale(@blog.locale) do
      mail(to: @subscriber.email, subject: I18n.t("email_subscribers.mailers.confirmation.subject", blog_name: @blog.display_name))
    end
  end
end
