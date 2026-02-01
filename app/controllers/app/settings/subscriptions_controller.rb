class App::Settings::SubscriptionsController < AppController
  before_action :load_subscription, only: [ :index, :destroy, :cancel_confirm, :change_plan, :resume ]

  def index
  end

  def thanks
  end

  def destroy
    Rails.logger.info "Cancelling subscription for #{Current.user.id}"

    if @subscription.present?
      response = PaddleApi.new.cancel_subscription(@subscription.paddle_subscription_id)
      Rails.logger.info response
      @subscription.update!(cancelled_at: Time.current)
      SendCancellationEmailJob.set(wait: 4.hours).perform_later(Current.user.id, subscriber: true)
    end

    redirect_to app_settings_path
  end

  def cancel_confirm
    redirect_to app_settings_path if @subscription.blank? || @subscription.cancelled?
  end

  def change_plan
    new_plan = params[:plan]
    return redirect_to app_settings_subscriptions_path, alert: "Invalid plan" unless %w[monthly annual].include?(new_plan)

    response = PaddleApi.new.update_subscription_items(@subscription.paddle_subscription_id, SubscriptionsHelper.price_id(new_plan))

    if response.success?
      redirect_to app_settings_path, notice: "Your plan has been updated to #{new_plan}!"
    else
      redirect_to app_settings_subscriptions_path, alert: "Unable to change plan. Please try again."
    end
  end

  def resume
    return redirect_to app_settings_subscriptions_path unless @subscription&.cancelled?

    response = PaddleApi.new.resume_subscription(@subscription.paddle_subscription_id)

    if response.success?
      @subscription.update!(cancelled_at: nil)
      redirect_to app_settings_path, notice: "Your subscription has been resumed!"
    else
      redirect_to app_settings_subscriptions_path, alert: "Unable to resume subscription. Please try again."
    end
  end

  private

    def load_subscription
      @subscription = Current.user.subscription
    end
end
