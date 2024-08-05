# Preview all emails at http://localhost:3000/rails/mailers/account_verification_mailer
class FreeTrialMailerPreview < ActionMailer::Preview
  def premium_only
    FreeTrialMailer.with(user: User.first).premium_only
  end
end
