class App::Settings::AppearanceController < AppController
  def index
  end

  def update
    if @blog.update(appearance_params)
      @blog.posts.touch_all # cache busting

      redirect_to app_settings_path, notice: "Appearance settings updated"
    else
      puts @blog.errors.full_messages
      render :index, status: :unprocessable_entity
    end
  end

  private

    def appearance_params
      permitted_params = [
        :bio, :title, :layout,
        :theme, :font, :width,
        social_links_attributes: [ :id, :platform, :url, :_destroy ]
      ]

      permitted_params << [
        :avatar,
        :show_branding
       ] if @blog.user.subscribed?

      params.require(:blog).permit(permitted_params)
    end
end
