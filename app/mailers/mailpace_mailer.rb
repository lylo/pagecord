class MailpaceMailer < ApplicationMailer
  default from: "Pagecord <hello@mailer.pagecord.com>"

  around_deliver do |mailer, block|
    block.call
  rescue Mailpace::DeliveryError => error
    context = { to: message.to, subject: message.subject, mailer: self.class.name }
    Appsignal.add_custom_data(context)

    if Sentry.initialized?
      Sentry.set_context("email", context)
      # A tag as well as context: Sentry aggregates tags on the issue page, so
      # the affected addresses are visible without opening an event.
      Sentry.set_tags(email_to: message.to&.first)
    end

    # MailPace refuses addresses on its own bounce and complaint list, so no
    # number of retries will get through. Report it once and let the job finish,
    # rather than raising and having Sidekiq try again for the next three weeks.
    raise error unless error.message.include?("blocked address")

    Sentry.capture_exception(error) if Sentry.initialized?
  end
end
