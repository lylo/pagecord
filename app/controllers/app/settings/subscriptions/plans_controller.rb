class App::Settings::Subscriptions::PlansController < App::BaseController
  PLANS = %w[ monthly annual supporter ].freeze

  def update
    subscription = Current.user.subscription
    new_plan = params[:plan]

    return redirect_to app_settings_subscriptions_path, alert: "Invalid plan" unless PLANS.include?(new_plan)

    # Moving from a yearly plan to monthly changes the billing interval, which Paddle reschedules
    # immediately (billing next month) rather than at the current term's end — it would forfeit
    # already-paid time. Not offered; monthly is only chosen at signup.
    if new_plan == "monthly" && !subscription.monthly?
      return redirect_to app_settings_subscriptions_path, alert: "Switching to monthly billing isn't available from a yearly plan."
    end

    # Downgrades take effect at the next billing cycle and never refund; upgrades bill the difference today.
    downgrade = Subscription.price(new_plan).to_i < Subscription.price(subscription.plan).to_i
    proration_billing_mode = downgrade ? "do_not_bill" : "prorated_immediately"

    response = PaddleApi.new.update_subscription_items(subscription.paddle_subscription_id, SubscriptionsHelper.price_id(new_plan), proration_billing_mode: proration_billing_mode)

    if response.success?
      # Optimistically reflect the switch now so the UI is correct even if the
      # subscription.updated webhook is delayed or missed. The webhook still
      # confirms unit_price and the next billing date.
      subscription.update!(plan: new_plan, paddle_price_id: SubscriptionsHelper.price_id(new_plan))
      redirect_to app_settings_path, notice: "Your plan has been updated to #{new_plan}!"
    else
      Rails.logger.error "Plan change failed for user #{Current.user.id} (#{subscription.paddle_subscription_id} -> #{new_plan}): HTTP #{response.code} #{response.body}"
      redirect_to app_settings_subscriptions_path, alert: failure_alert(response)
    end
  end

  private

    def failure_alert(response)
      if response.body.to_s.include?("subscription_payment_declined")
        "Your payment was declined. Please update your card details below, then try again."
      elsif response.body.to_s.include?("subscription_update_transaction_balance_less_than_charge_limit")
        "Your subscription is too close to its renewal date to switch plans right now. Please try again after it renews."
      else
        "Unable to change plan. Please try again."
      end
    end
end
