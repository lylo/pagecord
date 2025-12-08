class MailpaceMailer < ApplicationMailer
  self.delivery_method = :mailpace if Rails.env.production?

  default from: "Pagecord <no-reply@mailer.pagecord.com>"

  after_action :use_resend_if_configured

  private

    def use_resend_if_configured
      return unless Rails.env.production?
      return unless @blog && feature?(:resend, blog: @blog)

      message.delivery_method(Resend::Mailer, { api_key: Resend.api_key })
      message.from = "Pagecord <no-reply@remailer.pagecord.com>"
    end
end
