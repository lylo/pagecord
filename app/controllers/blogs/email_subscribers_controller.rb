class Blogs::EmailSubscribersController < Blogs::BaseController
  include SpamPrevention

  before_action :requires_user_subscription

  def create
    @subscriber = @blog.email_subscribers.new(email_subscriber_params)
    default_message = "Thanks for subscribing. Unless you're already subscribed, a confirmation email is on its way to #{@subscriber.email}"

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

    def requires_user_subscription
      head :unprocessable_entity unless @blog.user.subscribed?
    end

    def email_subscriber_params
      params.require(:email_subscriber).permit(:email)
    end
end
