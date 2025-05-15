# Preview email at http://localhost:3000/rails/mailers/email_change_mailer/verify
class EmailChangeMailerPreview < ActionMailer::Preview
  def verify
    email_change_request = EmailChangeRequest.new(
      user: User.first,
      new_email: "new_email@example.com",
      token_digest: "sample-token-digest-for-preview"
    )

    EmailChangeMailer.with(email_change_request: email_change_request).verify
  end
end
