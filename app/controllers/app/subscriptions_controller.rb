class App::SubscriptionsController < AppController
  before_action :load_subscription, only: [:destroy, :cancel_confirm]

  def thanks
  end

  def destroy
    Rails.logger.info "Cancelling subscription for #{Current.user.username}"

    if @subscription.present?
      response = PaddleApi.new.cancel_subscription(@subscription.paddle_subscription_id)
      Rails.logger.info response
      @subscription.update!(cancelled_at: Time.current)
    end

    redirect_to app_account_path
  end

  def cancel_confirm
  end

  private

    def load_subscription
      @subscription = Current.user.subscription
    end
end
