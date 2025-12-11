class PasswordResetMailer < MailpaceMailer
  def reset
    @user = params[:user]
    @access_request = @user.access_requests.create!(purpose: :password_reset)

    mail(to: @user.email, subject: "Reset your Pagecord password")
  end
end
