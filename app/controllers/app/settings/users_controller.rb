class App::Settings::UsersController < App::BaseController
  def update
    if Current.user.update(user_params)
      redirect_to app_settings_path, notice: "Account settings updated"
    else
      render :edit
    end
  end

  private

    def user_params
      params.require(:user).permit(:timezone)
    end
end
