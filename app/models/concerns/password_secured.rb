module PasswordSecured
  extend ActiveSupport::Concern

  included do
    has_secure_password validations: false

    validates :password, length: { minimum: 12 }, confirmation: true, allow_blank: true
  end

  def has_password?
    password_digest.present?
  end
end
