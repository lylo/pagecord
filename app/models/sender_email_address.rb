class SenderEmailAddress < ApplicationRecord
  include Verifiable

  MAX_PER_BLOG = 3

  belongs_to :blog

  validates :email, presence: true, uniqueness: { scope: :blog_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, uniqueness: true, allow_nil: true
  validate :email_not_user_email
  validate :sender_email_limit

  private

  def email_not_user_email
    if blog&.user&.email == email
      errors.add(:email, "cannot be the same as your account email")
    end
  end

  def sender_email_limit
    return unless blog.present? && new_record?

    if blog.sender_email_addresses.count >= MAX_PER_BLOG
      errors.add(:base, "Cannot add more than #{MAX_PER_BLOG} sender email addresses per blog")
    end
  end
end
