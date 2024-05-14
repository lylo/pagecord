class App::AccountController < AppController
  def index
    @subscription = Current.user.subscription
  end
end
