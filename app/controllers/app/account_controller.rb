class App::AccountController < App::BaseController
  def index
    @subscription = Current.user.subscription
  end
end
