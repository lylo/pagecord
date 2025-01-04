class Blogs::EmailSubscribersController < ApplicationController
  rate_limit to: 5, within: 1.minute

  before_action :load_blog, :requires_user_subscription
  skip_before_action :domain_check

  def create
    @subscriber = @blog.email_subscribers.new(email_subscriber_params)
    default_message = "Thanks for subscribing. Unless you're already subscribed, a confirmation email is on its way to #{@subscriber.email}"

    if @blog.email_subscribers.find_by(email: @subscriber.email)
      @message = default_message
    elsif @subscriber.save
      EmailSubscriptionConfirmationMailer.with(subscriber: @subscriber).confirm.deliver_later

      @message = default_message
    end
  end

  private

    def load_blog
      @blog = Blog.find_by!(name: params[:blog_name])
    end

    def requires_user_subscription
      head :unprocessable_entity unless @blog.user.subscribed?
    end

    def email_subscriber_params
      params.require(:email_subscriber).permit(:email)
    end
end
