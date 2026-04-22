class App::Settings::ApiController < AppController
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
end
