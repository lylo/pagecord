class EmailChangeMailer < ApplicationMailer
  def verify
    @email_change_request = params[:email_change_request]
    @user = @email_change_request.user
    @new_email = @email_change_request.new_email

    mail(
      to: @new_email,
      subject: "Verify your new Pagecord email address"
    )
  end
end
