class ApplicationMailer < ActionMailer::Base
  default from: "Pagecord <hello@cfmail.pagecord.com>",
          reply_to: "Pagecord <hello@pagecord.com>"

  layout "mailer"

  helper ImageHelper

  around_deliver :skip_undeliverable_recipient

  private

    def skip_undeliverable_recipient
      yield
    rescue CloudflareEmail::UndeliverableError, Postmark::InactiveRecipientError => error
      undeliverable_recipient(error)
    end

    def undeliverable_recipient(error)
      Rails.logger.warn "Email not delivered. #{self.class.name}##{action_name}: #{error.message}"
    end
end
