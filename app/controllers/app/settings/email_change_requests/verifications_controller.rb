class App::Settings::EmailChangeRequests::VerificationsController < App::BaseController
  def show
    if email_change_request = EmailChangeRequest.active.pending.find_by(token_digest: params[:token])
      email_change_request.accept!

      redirect_to edit_app_settings_account_path, notice: "Your email has been changed"
    else
      redirect_to root_path, alert: "This verification link is no longer valid"
    end
  end
end
