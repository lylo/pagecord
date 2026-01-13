class App::Settings::EmailChangeRequestsController < AppController
  def create
    @email_change_request = Current.user.email_change_requests.new(change_request_params)
    if @email_change_request.save
      send_email_change_request(@email_change_request)
    else
      redirect_to app_settings_account_edit_path, alert: @email_change_request.errors.full_messages.to_sentence
    end
  end

  def destroy
    @email_change_request = Current.user.email_change_requests.find(params[:id])
    if @email_change_request.destroy
      redirect_to app_settings_account_edit_path, notice: "Email change request has been cancelled"
    else
      redirect_to app_settings_account_edit_path, alert: "Unable to cancel email change request"
    end
  end

  def verify
    if email_change_request = EmailChangeRequest.active.pending.find_by(token_digest: params[:token])
      email_change_request.accept!

      sign_in user unless Current.user

      redirect_to app_settings_account_edit_path, notice: "Your email has been changed"
    else
      redirect_to root_path, alert: "This verification link is no longer valid"
    end
  end

  def resend
    if email_change_request = Current.user.pending_email_change_request
      send_email_change_request(email_change_request)
    else
      redirect_to app_settings_account_edit_path, alert: "No pending email change request found."
    end
  end

  private

    def change_request_params
      params.require(:email_change_request).permit(:new_email)
    end

    def send_email_change_request(email_change_request)
      EmailChangeMailer.with(email_change_request: email_change_request).verify.deliver_later
      redirect_to app_settings_account_edit_path, notice: "Email verification has been resent."
    end
end
