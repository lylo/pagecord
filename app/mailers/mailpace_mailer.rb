class MailpaceMailer < ApplicationMailer
  self.delivery_method = :mailpace if Rails.env.production?

  default from: "Pagecord <hello@mailer.pagecord.com>"
end
