class App::Settings::AboutController < AppController
  def index
  end

  def update
    if @blog.update(about_params)
      redirect_to app_settings_path, notice: "About settings updated"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

    def about_params
      permitted_params = [ :bio, :title ]
      permitted_params << :avatar if @blog.user.has_premium_access?

      params.require(:blog).permit(permitted_params)
    end
end
