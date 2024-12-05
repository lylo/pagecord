class App::Settings::SubscriptionsController < AppController
  before_action :load_subscription, only: [ :index, :destroy, :cancel_confirm ]

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
    end

    redirect_to app_settings_path
  end

  def cancel_confirm
    redirect_to app_settings_path if @subscription.blank? || @subscription.cancelled?
  end

  private

    def load_subscription
      @subscription = Current.user.subscription
    end
end
