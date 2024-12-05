module DeliveryEmail
  extend ActiveSupport::Concern

  included do
    before_create :generate_delivery_email
  end

  private

    MAIL_DOMAIN = "@post.pagecord.com"

    def generate_delivery_email
      code = Nanoid.generate(size: 8, alphabet: "0123456789abcdefghijklmnopqrstuvwxyz")

      self.delivery_email = "#{name}_#{code}#{MAIL_DOMAIN}" unless delivery_email.present?
    end
end
