class App::Onboardings::ThemesController < App::BaseController
  skip_before_action :onboarding_check

  def update
    template = ThemeTemplate.offered_to(@blog).find(params[:template_id]) if params[:template_id].present?
    @blog.apply_design(template)

    head :no_content
  end
end
