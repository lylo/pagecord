class App::Settings::UsersController < AppController
  def update
    if Current.user.update(user_params)
      redirect_to app_settings_path, notice: "Account settings updated"
    else
      render :edit
    end
  end

  def destroy
    DestroyUserJob.perform_later(@user.id)

    redirect_to root_path
  end

  private

    def user_params
      params.require(:user).permit(:timezone)
    end
end
