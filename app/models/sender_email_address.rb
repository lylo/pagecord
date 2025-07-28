class SenderEmailAddress < ApplicationRecord
  include Verifiable
  
  belongs_to :blog

  validates :email, presence: true, uniqueness: { scope: :blog_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, uniqueness: true, allow_nil: true
  validate :email_not_user_email

  private

  def email_not_user_email
    if blog&.user&.email == email
      errors.add(:email, "cannot be the same as your account email")
    end
  end
end
