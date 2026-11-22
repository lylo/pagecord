class NewsletterMailer < ApplicationMailer
  self.delivery_method = :postmark if Rails.env.production?

  default from: "Pagecord <hello@notifications.pagecord.com>"

  private

    def delivery_method_for(blog)
      :ses if Rails.env.production? && blog.user.ses_newsletter_delivery?
    end
end
