class ResendMailer < ApplicationMailer
  self.delivery_method = :resend if Rails.env.production?

  default from: "Pagecord <hello@remailer.pagecord.com>"
end
