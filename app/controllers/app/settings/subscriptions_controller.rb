class App::Settings::SubscriptionsController < App::BaseController
  def index
    @subscription = Current.user.subscription
  end
end
