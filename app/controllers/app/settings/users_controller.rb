class App::Settings::UsersController < AppController
  def edit
  end

  def update
    if @user.update(user_params)
      if @user.domain_changed?
        if @user.custom_domain.present?
          AddCustomDomainJob.perform_later(@user.id, @user.custom_domain)
        else
          RemoveCustomDomainJob.perform_later(@user.id, @user.custom_domain_previously_was)
        end
      end

      redirect_to app_settings_path, notice: "Appearance settings updated"
    else
      render :index
    end
  end

  def destroy
    DestroyUserJob.perform_later(@user.id)

    redirect_to root_path
  end

  private

    def user_params
      if @user.subscribed?
        params.require(:user).permit(:bio, :custom_domain, :title)
      else
        params.require(:user).permit(:bio)
      end
    end
end
