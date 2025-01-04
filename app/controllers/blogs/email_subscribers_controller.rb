class Blogs::EmailSubscribersController < ApplicationController
  before_action :load_blog, :requires_user_subscription
  skip_before_action :domain_check

  def create
    @subscriber = @blog.email_subscribers.new(email_subscriber_params)

    if @blog.email_subscribers.find_by(email: @subscriber.email)
      @message = "#{@subscriber.email} is already subscribed"
    elsif @subscriber.save
      EmailSubscriptionConfirmationMailer.with(subscriber: @subscriber).confirm.deliver_later

      @message = "Thanks for subscribing. A confirmation email is on its way to #{@subscriber.email}"
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
