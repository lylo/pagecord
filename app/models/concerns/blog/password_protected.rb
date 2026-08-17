module Blog::PasswordProtected
  extend ActiveSupport::Concern

  PASSWORD_RANGE = 6..72

  included do
    has_secure_password validations: false

    attribute :use_password, :boolean
    attr_writer :access_granted

    scope :not_password_protected, -> { where(password_digest: nil) }

    before_validation :clear_password, if: -> { use_password == false }
    validates :password, length: { in: PASSWORD_RANGE }, allow_blank: true
    validate :password_set_when_requested
  end

  def password_protected?
    password_digest.present?
  end

  # Set per request once the visitor is past the login page. A blog with no
  # password has nothing to grant.
  def access_granted?
    !password_protected? || @access_granted.present?
  end

  # Derived from the digest rather than stored, so it cycles with the password
  # and dies when protection is removed.
  def feed_token
    Digest::SHA256.hexdigest(password_digest).first(32) if password_protected?
  end

  def valid_feed_token?(candidate)
    feed_token.present? && ActiveSupport::SecurityUtils.secure_compare(feed_token, candidate.to_s)
  end

  def feed_params
    password_protected? ? { key: feed_token } : {}
  end

  private

    def clear_password
      self.password = nil
    end

    # A blank password leaves the existing one alone, so this only fires when
    # protection is asked for and there's nothing to fall back on.
    def password_set_when_requested
      return unless use_password && password_digest.blank?

      errors.add(:password, "can't be blank")
    end
end
