class PostmarkMailer < ApplicationMailer
  self.delivery_method = :postmark if Rails.env.production?

  default from: "no-reply@notifications.pagecord.com"
end
