class AccountVerificationMailer < MailpaceMailer
  def verify
    @user = params[:user]
    @access_request = @user.access_requests.create!

    mail(to: @user.email, subject: "Verify your Pagecord email address")
  end

  def login
    @user = params[:user]
    @access_request = @user.access_requests.create!

    mail(to: @user.email, subject: "Log into your Pagecord account")
  end
end
