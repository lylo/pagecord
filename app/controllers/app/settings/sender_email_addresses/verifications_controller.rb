class App::Settings::SenderEmailAddresses::VerificationsController < App::BaseController
  skip_before_action :load_user, :onboarding_check, :require_login

  def show
    sender_email_address = SenderEmailAddress.find_by(token_digest: params[:token])
    redirect_path = Current.user ? edit_app_settings_account_path : login_path

    if sender_email_address && !sender_email_address.accepted? && !sender_email_address.expired?
      sender_email_address.accept!

      redirect_to redirect_path, notice: "Email address has been verified! You can now post to your blog from #{sender_email_address.email}."
    else
      redirect_to redirect_path, alert: "Invalid or expired verification link :("
    end
  end
end
