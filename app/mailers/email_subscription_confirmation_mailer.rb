class EmailSubscriptionConfirmationMailer < MailpaceMailer
  include RoutingHelper
  layout "mailer_minimal"
  helper RoutingHelper

  def confirm
    @subscriber = params[:subscriber]

    # Mailpace rebuilds the message from a fixed set of API fields, so
    # List-Unsubscribe-Post never reaches the wire and one-click is unavailable.
    # Point at the confirmation page, which answers a GET.
    headers["List-Unsubscribe"] = "<#{email_subscriber_unsubscribe_url_for(@subscriber)}>"

    I18n.with_locale(@subscriber.blog.locale) do
      mail(to: @subscriber.email, subject: I18n.t("email_subscribers.mailers.confirmation.subject", blog_name: @subscriber.blog.display_name))
    end
  end
end
