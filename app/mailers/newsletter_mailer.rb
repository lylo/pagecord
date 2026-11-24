class NewsletterMailer < ApplicationMailer
  self.delivery_method = :ses if Rails.env.production?

  default from: "Pagecord <hello@notifications.pagecord.com>"
end
