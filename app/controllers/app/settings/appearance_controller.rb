class App::Settings::AppearanceController < AppController
  before_action :set_templates, only: :index

  def index
  end

  def update
    if @blog.update(appearance_params)
      respond_to do |format|
        format.turbo_stream { head :no_content }
        format.html { redirect_to app_settings_path, notice: "Appearance settings updated" }
      end
    else
      set_templates
      render :index, status: :unprocessable_entity
    end
  end

  private

    def set_templates
      @templates = ThemeTemplate.active.ordered.limit(6)
    end

    def appearance_params
      permitted_params = [
        :layout, :theme, :font, :width,
        :custom_theme_bg_light, :custom_theme_text_light, :custom_theme_accent_light,
        :custom_theme_bg_dark, :custom_theme_text_dark, :custom_theme_accent_dark
      ]

      permitted_params << :show_branding if @blog.user.subscribed?

      params.require(:blog).permit(permitted_params)
    end
end
