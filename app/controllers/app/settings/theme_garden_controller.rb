class App::Settings::ThemeGardenController < App::BaseController
  skip_before_action :onboarding_check

  def index
    @templates = ThemeTemplate.offered_to(@blog).ordered
  end
end
