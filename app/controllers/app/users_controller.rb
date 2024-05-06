require "httparty"

class App::UsersController < AppController
  before_action :load_user

  def update
    if @user.update(user_params)
      if domain_change?
        if @user.custom_domain.present?
          AddCustomDomainJob.perform_later(@user.id, @user.custom_domain)
        else
          RemoveCustomDomainJob.perform_later(@user.id, @user.custom_domain_previously_was)
        end
      end

      respond_to do |format|
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.update("form-response", partial: "form_response", locals: { message: '❌ Failed' })
        }
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
        params.require(:user).permit(:bio, :custom_domain)
      else
        params.require(:user).permit(:bio)
      end
    end

    def domain_change?
      # we don't want a nil to "" to be considered a domain change
      nil_to_blank_change = (@user.custom_domain_previously_was.nil? && @user.custom_domain.blank?) ||
        (@user.custom_domain_previously_was.blank? && @user.custom_domain.nil?)

      @user.custom_domain_previously_changed? && !nil_to_blank_change
    end
end
