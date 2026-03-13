class MailpaceMailer < ApplicationMailer
  default from: "Pagecord <hello@mailer.pagecord.com>"

  around_deliver do |mailer, block|
    block.call
  rescue Mailpace::DeliveryError => error
    context = { to: message.to, subject: message.subject, mailer: self.class.name }
    Appsignal.add_custom_data(context)
    Sentry.set_context("email", context) if Sentry.initialized?
    raise error
  end
end
