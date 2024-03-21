# Preview all emails at http://localhost:3000/rails/mailers/account_verification_mailer
class AccountVerificationMailerPreview < ActionMailer::Preview
  def verify
    AccountVerificationMailer.with(user: User.first).verify
  end
end
