require "httparty"

class App::UsersController < AppController
  before_action :load_user

  def update
    if @user.update(user_params)
      handle_custom_domain_ssl if @user.custom_domain_previously_changed?

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @user }
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

    # Move this to the model perhaps?
    def handle_custom_domain_ssl
      if @user.custom_domain.present?
        if Rails.env.production?
          # FIXME create an API class for this and background it
          response = HTTParty.post(
            "https://app.hatchbox.io/api/v1/accounts/2928/apps/6347/domains",
            headers: {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{ENV['HATCHBOX_API_KEY']}"
            },
            body: {
              domain: {
                name: @user.custom_domain
              }
            }
          )
          Rails.logger.info response
          Rails.logger.info "SSL certificate issued for custom domain"
        end
      else
        if Rails.env.production?
          # FIXME create an API class for this and background it
          # There's also a danger that existing domains can be removed here!
          response = HTTParty.delete(
            "https://app.hatchbox.io/api/v1/accounts/2928/apps/6347/domains/#{@user.custom_domain_previously_was}",
            headers: {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{ENV['HATCHBOX_API_KEY']}"
            }
          )

          Rails.logger.info response
          Rails.logger.info "SSL certificate revoked for custom domain"
        end
      end
      @user.posts.touch_all
    end
end
