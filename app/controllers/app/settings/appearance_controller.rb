class App::Settings::AppearanceController < AppController
  def index
  end

  def update
    if @blog.update(appearance_params)
      @blog.posts.touch_all # cache busting

      redirect_to app_settings_path, notice: "Appearance settings updated"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

    def appearance_params
      permitted_params = [
        :bio, :title, :layout,
        :theme, :font, :width,
        :custom_theme_bg_light, :custom_theme_text_light, :custom_theme_accent_light,
        :custom_theme_bg_dark, :custom_theme_text_dark, :custom_theme_accent_dark
      ]

      if @blog.user.subscribed?
        permitted_params += [ :avatar, :show_branding ]
      end

      permitted_params << :custom_css if current_features.enabled?(:custom_css)

      params.require(:blog).permit(permitted_params)
    end
end
