class App::Onboardings::PasswordsController < App::BaseController
  skip_before_action :onboarding_check
  before_action -> { head :forbidden }, if: -> { Current.user.has_password? }

  def create
    if password_params[:password].present? && Current.user.update(password_params)
      render turbo_stream: turbo_stream.update("onboarding_password", partial: "app/onboardings/password_set")
    else
      render turbo_stream: turbo_stream.update("password_error", Current.user.errors.full_messages.first || "Enter a password"), status: :unprocessable_entity
    end
  end

  private

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
end
