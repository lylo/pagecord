class PostmarkMailer < ApplicationMailer
  self.delivery_method = :postmark if Rails.env.production?

  default from: "Pagecord <hello@notifications.pagecord.com>"
end
