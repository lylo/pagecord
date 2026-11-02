class App::Settings::Subscriptions::CancellationsController < App::BaseController
  before_action :load_subscription

  def new
    @cancellation = Cancellation.new
  end

  def create
    @cancellation = Cancellation.new(cancellation_params.merge(user: Current.user, kind: :subscription, plan: @subscription.plan))
    return render(:new, status: :unprocessable_entity) if @cancellation.invalid?

    Rails.logger.info "Cancelling subscription for #{Current.user.id}"

    PaddleApi.new.cancel_subscription(@subscription.paddle_subscription_id)
    @subscription.update!(cancelled_at: Time.current)
    @cancellation.save!
    SendCancellationEmailJob.set(wait: 4.hours).perform_later(Current.user.id, subscriber: true)

    BillingEventLog.record(:cancel_requested, for_subscription: @subscription, effective: @subscription.next_billed_at, source: "app", cancel_reason: @cancellation.reason, feedback: @cancellation.feedback)

    redirect_to app_settings_path, notice: "Your subscription has been cancelled. You'll keep access until the end of your current billing period."
  rescue PaddleApi::Error => error
    Sentry.capture_exception(error) if Sentry.initialized?
    redirect_to new_app_settings_subscriptions_cancellation_path, flash: { error: "I couldn't cancel your subscription just now. Please try again, or email hello@pagecord.com." }
  end

  private

    def load_subscription
      @subscription = Current.user.subscription
      redirect_to app_settings_path if @subscription.blank? || @subscription.cancelled?
    end

    def cancellation_params
      params.expect(cancellation: [ :reason, :feedback ])
    end
end
