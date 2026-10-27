class App::Settings::ThemeGarden::ApplicationsController < App::BaseController
  skip_before_action :onboarding_check

  def create
    template = ThemeTemplate.offered_to(@blog).find(params[:theme_garden_id]) unless params[:theme_garden_id] == "classic"

    if @blog.apply_design(template)
      redirect_to app_settings_appearance_path, notice: "\"#{template&.name || "Classic"}\" design applied"
    else
      redirect_to app_settings_theme_garden_index_path, alert: "Could not apply design"
    end
  end
end
