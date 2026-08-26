class App::Settings::EmailChangeRequestsController < App::BaseController
  def create
    @email_change_request = Current.user.email_change_requests.new(change_request_params)

    if @email_change_request.save
      EmailChangeMailer.with(email_change_request: @email_change_request).verify.deliver_later
      redirect_to edit_app_settings_account_path, notice: "Email verification has been resent."
    else
      redirect_to edit_app_settings_account_path, alert: @email_change_request.errors.full_messages.to_sentence
    end
  end

  def destroy
    @email_change_request = Current.user.email_change_requests.find(params[:id])

    if @email_change_request.destroy
      redirect_to edit_app_settings_account_path, notice: "Email change request has been cancelled"
    else
      redirect_to edit_app_settings_account_path, alert: "Unable to cancel email change request"
    end
  end

  private

    def change_request_params
      params.require(:email_change_request).permit(:new_email)
    end
end
