class App::Settings::ApiController < App::BaseController
  before_action :require_premium, only: [ :create, :destroy ]
  before_action :set_connections, only: [ :show, :create ]

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

    def set_connections
      @connections = @blog.mcp_connections.active.order(created_at: :desc).load
    end

    def require_premium
      render_app_not_found unless Current.user.has_premium_access?
    end
end
