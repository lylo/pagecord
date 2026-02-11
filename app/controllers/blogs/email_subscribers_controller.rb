class Blogs::EmailSubscribersController < Blogs::BaseController
  include SpamPrevention

  rate_limit to: 3, within: 1.hour, only: [ :create ]

  before_action :requires_user_subscription

  def create
    @subscriber = @blog.email_subscribers.new(email_subscriber_params)
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

    def fail
      @message = "There's an issue with your subscription. If you're using a VPN, try subscribing without it. Contact support if the problem persists."

      respond_to do |format|
        format.turbo_stream { render :create }
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
