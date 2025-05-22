class PostmarkMailer < ApplicationMailer
  self.delivery_method = :postmark if Rails.env.production?

  default from: "Pagecord <no-reply@notifications.pagecord.com>"
end
