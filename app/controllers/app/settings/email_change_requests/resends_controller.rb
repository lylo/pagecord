class App::Settings::EmailChangeRequests::ResendsController < App::BaseController
  def create
    if email_change_request = Current.user.pending_email_change_request
      EmailChangeMailer.with(email_change_request: email_change_request).verify.deliver_later
      redirect_to edit_app_settings_account_path, notice: "Email verification has been resent."
    else
      redirect_to edit_app_settings_account_path, alert: "No pending email change request found."
    end
  end
end
