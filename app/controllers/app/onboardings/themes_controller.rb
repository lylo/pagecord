class App::Onboardings::ThemesController < App::BaseController
  skip_before_action :onboarding_check

  def update
    template = ThemeTemplate.active.find(params[:template_id])
    @blog.update(template.appearance_attributes)

    head :no_content
  end
end
