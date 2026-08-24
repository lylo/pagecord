class App::Settings::ThemeGarden::ApplicationsController < App::BaseController
  skip_before_action :onboarding_check

  def create
    template = ThemeTemplate.active.find(params[:theme_garden_id])

    if @blog.update(template.appearance_attributes)
      redirect_to app_settings_appearance_path, notice: "\"#{template.name}\" template applied"
    else
      redirect_to app_settings_theme_garden_index_path, alert: "Could not apply template"
    end
  end
end
