class Blogs::EmailSubscribersController < ApplicationController
  before_action :load_blog

  def create
    @subscriber = @blog.email_subscribers.new(email_subscriber_params)

    if @blog.email_subscribers.find_by(email: @subscriber.email)
      @message = "#{@subscriber.email} is already subscribed"
    elsif @subscriber.save
      @message = "Thanks for subscribing. A confirmation email is on its way to #{@subscriber.email}"
    end
  end

  def destroy
  end

  private

    def load_blog
      @blog = Blog.find_by!(name: params[:name])
    end

    def email_subscriber_params
      params.require(:email_subscriber).permit(:email)
    end
end
