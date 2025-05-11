class App::Settings::AudienceController < AppController
  def index
    redirect_to app_settings_path unless current_user.subscribed?
  end
end
