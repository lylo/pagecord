class App::Settings::Subscriptions::PaddleInvoicesController < AppController
  ALLOWED_HOSTS = %w[customer-portal.paddle.com sandbox-customer-portal.paddle.com].freeze

  def show
    subscription = Current.user.subscription
    return redirect_to app_settings_subscriptions_path if subscription&.paddle_customer_id.blank?

    response = PaddleApi.new.create_customer_portal_session(
      subscription.paddle_customer_id,
      [ subscription.paddle_subscription_id ].compact
    )
    url = response.dig("data", "urls", "general", "overview")

    if url.present? && ALLOWED_HOSTS.include?(URI.parse(url).host)
      redirect_to url, allow_other_host: true
    else
      redirect_to app_settings_subscriptions_path, alert: "Unable to open invoices. Please try again."
    end
  rescue URI::InvalidURIError
    redirect_to app_settings_subscriptions_path, alert: "Unable to open invoices. Please try again."
  end
end
