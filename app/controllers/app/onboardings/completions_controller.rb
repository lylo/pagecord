class App::Onboardings::CompletionsController < App::BaseController
  skip_before_action :onboarding_check

  def create
    Current.user.onboarding_complete!

    redirect_to app_root_path, notice: "Welcome to Pagecord!"
  end
end
