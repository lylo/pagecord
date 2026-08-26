class App::Settings::Subscriptions::PlansController < App::BaseController
  ALERTS = {
    unknown_plan: "Invalid plan",
    monthly_from_yearly: "Switching to monthly billing isn't available from a yearly plan.",
    payment_declined: "Your payment was declined. Please update your card details below, then try again.",
    too_close_to_renewal: "Your subscription is too close to its renewal date to switch plans right now. Please try again after it renews.",
    unknown: "Unable to change plan. Please try again."
  }.freeze

  def update
    if error = Current.user.subscription.change_plan_to(params[:plan])
      redirect_to app_settings_subscriptions_path, alert: ALERTS.fetch(error)
    else
      redirect_to app_settings_path, notice: "Your plan has been updated to #{params[:plan]}!"
    end
  end
end
