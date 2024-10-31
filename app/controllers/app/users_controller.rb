require "httparty"

class App::UsersController < AppController
  before_action :load_user

  def update
    if @user.update(user_params)
      if @user.domain_changed?
        if @user.custom_domain.present?
          AddCustomDomainJob.perform_later(@user.id, @user.custom_domain)
        else
          RemoveCustomDomainJob.perform_later(@user.id, @user.custom_domain_previously_was)
        end
      end
    end
  end

  def destroy
    DestroyUserJob.perform_later(@user.id)

    redirect_to root_path
  end

  private

    def load_user
      @user = Current.user
    end

    def user_params
      if @user.is_premium?
        params.require(:user).permit(:bio, :custom_domain, :title)
      else
        params.require(:user).permit(:bio)
      end
    end
end
