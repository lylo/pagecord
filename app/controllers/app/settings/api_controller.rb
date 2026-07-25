class App::Settings::ApiController < AppController
  before_action :require_premium, only: [ :create, :destroy ]

  def show
  end

  def create
    @api_key = @blog.generate_api_key!
    render :show, status: :see_other
  end

  def destroy
    @blog.revoke_api_key!
    redirect_to app_settings_api_path
  end

  private

    def require_premium
      render_app_not_found unless Current.user.has_premium_access?
    end
end
