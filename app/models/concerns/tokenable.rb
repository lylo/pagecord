module Tokenable
  extend ActiveSupport::Concern

  included do
    # Use prepend: true to ensure this runs before other before_validation callbacks
    before_validation :set_token, prepend: true
  end

  private

    def set_token
      self.token ||= generate_unique_token
    end

    def generate_unique_token
      loop do
        token = SecureRandom.hex(4)
        break token unless self.class.exists?(token: token)
      end
    end
end
