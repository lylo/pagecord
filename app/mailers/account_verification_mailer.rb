class AccountVerificationMailer < ApplicationMailer

  def verify
    @user = params[:user]
    @access_request = @user.access_requests.create!

    mail(to: @user.email, subject: "📃 Verify your Pagecord email address")
  end
end
