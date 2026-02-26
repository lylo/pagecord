class EmailChangeRequest < ApplicationRecord
  include Verifiable

  belongs_to :user, inverse_of: nil

  validates :new_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :new_email_not_taken

  def accept!
    user.update!(email: new_email)
    super
  end

  private

    def new_email_not_taken
      if User.exists?(email: new_email)
        errors.add(:base, "Email is already in use")
      end
    end
end
