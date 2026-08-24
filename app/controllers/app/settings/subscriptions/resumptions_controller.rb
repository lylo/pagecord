class App::Settings::Subscriptions::ResumptionsController < App::BaseController
  def create
    subscription = Current.user.subscription

    return redirect_to app_settings_subscriptions_path unless subscription&.cancelled?

    if PaddleApi.new.resume_subscription(subscription.paddle_subscription_id).success?
      subscription.update!(cancelled_at: nil)
      redirect_to app_settings_path, notice: "Your subscription has been resumed!"
    else
      redirect_to app_settings_subscriptions_path, alert: "Unable to resume subscription. Please try again."
    end
  end
end
