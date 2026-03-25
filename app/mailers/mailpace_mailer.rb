class MailpaceMailer < ApplicationMailer
  default from: "Pagecord <hello@mailer.pagecord.com>"

  after_action :route_to_cloudflare

  around_deliver do |mailer, block|
    block.call
  rescue Mailpace::DeliveryError => error
    context = { to: message.to, subject: message.subject, mailer: self.class.name }
    Appsignal.add_custom_data(context)
    Sentry.set_context("email", context) if Sentry.initialized?
    raise error
  end

  private

  def route_to_cloudflare
    return unless ENV["CLOUDFLARE_EMAIL_API_TOKEN"].present?
    return unless @blog&.features&.include?("cloudflare_email")
    message.delivery_method(:cloudflare_email)
  end
end
