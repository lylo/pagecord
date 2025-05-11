class App::Settings::AudienceController < AppController
  def index
    redirect_to app_settings_path unless Current.user.subscribed?
  end
end
