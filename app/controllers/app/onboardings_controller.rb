class App::OnboardingsController < App::BaseController
  skip_before_action :onboarding_check
  before_action -> { redirect_to app_posts_path }, if: -> { Current.user.onboarding_complete? }

  layout "letter"

  def show
    @templates = ThemeTemplate.offered_to(@blog).ordered
  end
end
