module Blog::PasswordProtected
  extend ActiveSupport::Concern

  included do
    has_secure_password validations: false

    attribute :use_password, :boolean

    scope :publicly_viewable, -> { where(password_digest: nil) }

    before_validation :clear_password, if: -> { use_password == false }
    validate :password_set_when_requested
  end

  def password_protected?
    password_digest.present?
  end

  # A feed reader can't hold the unlock cookie, so a protected blog serves its
  # feed from a secret URL instead. Deriving the token from the digest means it
  # cycles with the password and dies when protection is removed – there's
  # nothing to store or keep in step.
  def feed_token
    Digest::SHA256.hexdigest(password_digest).first(32) if password_protected?
  end

  def valid_feed_token?(candidate)
    feed_token.present? && ActiveSupport::SecurityUtils.secure_compare(feed_token, candidate.to_s)
  end

  # Query params every link to this blog's feed needs, so the token is only
  # ever spelled out in one place.
  def feed_params
    password_protected? ? { key: feed_token } : {}
  end

  private

    def clear_password
      self.password = nil
    end

    # A blank password on update leaves the existing one alone, so the only way
    # to arrive here protected-but-passwordless is ticking the box without
    # typing anything.
    def password_set_when_requested
      return unless use_password && password_digest.blank?

      errors.add(:password, "can't be blank")
    end
end
