class ResendMailer < ApplicationMailer
  self.delivery_method = :resend if Rails.env.production?

  default from: "Pagecord <no-reply@remailer.pagecord.com>"
end
