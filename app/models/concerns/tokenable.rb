module Tokenable
  extend ActiveSupport::Concern

  included do
    before_create :set_token
  end

  private

    def set_token
      loop do
        self.token = SecureRandom.hex(4)
        break unless self.class.exists?(token: token)
      end
    end
end
