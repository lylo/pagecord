class MailpaceMailer < ApplicationMailer
  self.delivery_method = :mailpace if Rails.env.production?

  default from: "Pagecord <no-reply@mailer.pagecord.com>"
end
