# Preview email at http://localhost:3000/rails/mailers/sender_email_address_mailer/verify
class SenderEmailAddressMailerPreview < ActionMailer::Preview
  def verify
    user = User.first
    blog = user.blog
    sender_email_address = SenderEmailAddress.new(
      blog: blog,
      email: "sender@example.com",
      token_digest: SecureRandom.hex(24)
    )

    SenderEmailAddressMailer.with(sender_email_address: sender_email_address).verify
  end
end
