class App::OnboardingsController < App::BaseController
  skip_before_action :onboarding_check

  layout "letter"

  def show
    @templates = ThemeTemplate.active.ordered
  end
end
