module PasswordSecured
  extend ActiveSupport::Concern

  # bcrypt hashes the first 72 bytes and ignores the rest.
  MAX_BYTES = 72

  included do
    has_secure_password validations: false

    validate :password_within_byte_limit
  end

  def has_password?
    password_digest.present?
  end

  private

    def password_within_byte_limit
      return if password.blank?

      errors.add(:password, :password_too_long) if password.bytesize > MAX_BYTES
    end
end
