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

    redirect_to app_settings_path, notice: "Your subscription has been cancelled. You'll keep access until the end of your current billing period."
  end

  def cancel_confirm
    redirect_to app_settings_path if @subscription.blank? || @subscription.cancelled?
  end

  def change_plan
    new_plan = params[:plan]
    return redirect_to app_settings_subscriptions_path, alert: "Invalid plan" unless %w[monthly annual supporter].include?(new_plan)

    # Moving from a yearly plan to monthly changes the billing interval, which Paddle reschedules
    # immediately (billing next month) rather than at the current term's end — it would forfeit
    # already-paid time. Not offered; monthly is only chosen at signup.
    if new_plan == "monthly" && !@subscription.monthly?
      return redirect_to app_settings_subscriptions_path, alert: "Switching to monthly billing isn't available from a yearly plan."
    end

    # Downgrades take effect at the next billing cycle and never refund; upgrades bill the difference today.
    downgrade = Subscription.price(new_plan).to_i < Subscription.price(@subscription.plan).to_i
    proration_billing_mode = downgrade ? "do_not_bill" : "prorated_immediately"

    response = PaddleApi.new.update_subscription_items(@subscription.paddle_subscription_id, SubscriptionsHelper.price_id(new_plan), proration_billing_mode: proration_billing_mode)

    if response.success?
      # Optimistically reflect the switch now so the UI is correct even if the
      # subscription.updated webhook is delayed or missed. The webhook still
      # confirms unit_price and the next billing date.
      @subscription.update!(plan: new_plan, paddle_price_id: SubscriptionsHelper.price_id(new_plan))
      redirect_to app_settings_path, notice: "Your plan has been updated to #{new_plan}!"
    else
      Rails.logger.error "change_plan failed for user #{Current.user.id} (#{@subscription.paddle_subscription_id} -> #{new_plan}): HTTP #{response.code} #{response.body}"
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
