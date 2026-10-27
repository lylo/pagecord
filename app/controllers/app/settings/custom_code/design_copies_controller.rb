class App::Settings::CustomCode::DesignCopiesController < App::BaseController
  before_action :require_premium

  def create
    name = @blog.theme_template.name

    if @blog.detach_design
      redirect_to app_settings_custom_code_path, notice: "#{name}'s CSS is now your Custom CSS"
    else
      redirect_to app_settings_custom_code_path, alert: @blog.errors.full_messages.to_sentence
    end
  end

  private

    def require_premium
      render_app_not_found unless Current.user.has_premium_access?
    end
end
