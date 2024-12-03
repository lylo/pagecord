class App::Settings::AccountController < AppController
  def edit
    @subscription = Current.user.subscription
  end
end
