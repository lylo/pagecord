class CloudflareMailer < ApplicationMailer
  self.delivery_method = :cloudflare_email if Rails.env.production?

  default from: "Pagecord <hello@cfmail.pagecord.com>"
end
