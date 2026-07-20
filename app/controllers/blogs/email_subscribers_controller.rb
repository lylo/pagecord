class Blogs::EmailSubscribersController < Blogs::BaseController
  include SpamPrevention

  rate_limit to: 10, within: 1.hour, only: [ :create ], with: :rate_limit_reached

  skip_forgery_protection # Cached pages have no session cookie for CSRF verification
  skip_before_action :turnstile_check # The subscribe form is embedded on every blog page; no widget is rendered
  before_action :requires_user_subscription

  def create
    @subscriber = @blog.email_subscribers.new(email_subscriber_params)
    @subscriber.country = request.headers["CF-IPCountry"]
    default_message = I18n.t("email_subscribers.create.success_message", email: @subscriber.email)

    if @blog.email_subscribers.find_by(email: @subscriber.email)
      @message = default_message
    elsif @subscriber.save
      EmailSubscriptionConfirmationMailer.with(subscriber: @subscriber).confirm.deliver_later
      @message = default_message
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to blog_posts_path, notice: @message }
    end
  end

  private

    def submitted_email
      params.dig(:email_subscriber, :email)
    end

    def reject_submission
      @message = "There's an issue with your subscription. If you're using a VPN, try subscribing without it. Contact support if the problem persists."

      respond_to do |format|
        format.turbo_stream { render :create }
        format.html { redirect_to blog_posts_path, alert: @message }
      end
    end

    def rate_limit_reached
      @message = I18n.t(
        "email_subscribers.create.rate_limit_message",
        default: "You've tried to subscribe too many times, too quickly. Please try again later."
      )

      respond_to do |format|
        format.turbo_stream { render :create, status: :too_many_requests }
        format.html { redirect_to blog_posts_path, alert: @message }
      end
    end

    def requires_user_subscription
      head :unprocessable_entity unless @blog.user.subscribed?
    end

    def email_subscriber_params
      params.require(:email_subscriber).permit(:email)
    end
end
