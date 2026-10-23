module DeliveryEmail
  extend ActiveSupport::Concern

  included do
    before_create :generate_delivery_email
  end

  private

    MAIL_DOMAIN = "@post.pagecord.com"

    def generate_delivery_email
      code = SecureRandom.alphanumeric(8, chars: "0123456789abcdefghijklmnopqrstuvwxyz".chars)

      self.delivery_email = "#{subdomain}_#{code}#{MAIL_DOMAIN}" unless delivery_email.present?
    end
end
