class McpConnection < ApplicationRecord
  CODE_LIFETIME = 10.minutes

  belongs_to :blog

  scope :active, -> { where.not(token_digest: nil) }

  def self.find_by_token(token)
    active.joins(:blog).merge(Blog.kept).find_by(token_digest: digest(token))
  end

  def self.find_by_code(code)
    where(code_expires_at: Time.current..).find_by(code_digest: digest(code.to_s))
  end

  def self.digest(value)
    Digest::SHA256.hexdigest(value)
  end

  def issue_code!
    SecureRandom.hex(32).tap do |code|
      update!(code_digest: self.class.digest(code), code_expires_at: CODE_LIFETIME.from_now)
    end
  end

  def issue_token!
    SecureRandom.hex(32).tap do |token|
      update!(token_digest: self.class.digest(token), code_digest: nil, code_challenge: nil, code_expires_at: nil)
    end
  end

  def verifies?(code_verifier)
    code_challenge == Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier.to_s), padding: false)
  end
end
