class StandardSite::Account < ApplicationRecord
  self.table_name = "standard_site_accounts"

  belongs_to :blog

  validates :handle, :did, :pds_url, presence: true
  validates :blog_id, uniqueness: true
  validates :did, format: { with: /\Adid:[a-z0-9]+:[A-Za-z0-9._:%-]+\z/ }

  normalizes :handle, with: ->(handle) { handle.to_s.delete_prefix("@").strip.downcase }
  normalizes :pds_url, with: ->(url) { url.to_s.strip.delete_suffix("/") }

  def connected?
    disconnected_at.nil?
  end

  def access_jwt
    decrypt(access_jwt_ciphertext)
  end

  def access_jwt=(value)
    self.access_jwt_ciphertext = encrypt(value)
  end

  def refresh_jwt
    decrypt(refresh_jwt_ciphertext)
  end

  def refresh_jwt=(value)
    self.refresh_jwt_ciphertext = encrypt(value)
  end

  private

    def encrypt(value)
      return if value.blank?
      crypt.encrypt_and_sign(value)
    end

    def decrypt(value)
      return if value.blank?
      crypt.decrypt_and_verify(value)
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def crypt
      key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("standard-site-account", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
end
