class Blogs::EmailSubscribersController < ApplicationController
  rate_limit to: 1, within: 5.minutes, only: [ :create ]

  before_action :load_blog, :requires_user_subscription, :form_complete_time_check, :honeypot_check, :ip_reputation_check, only: [ :create ]
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

    def honeypot_check
      unless params[:email_confirmation].blank?
        Rails.logger.warn "Honeypot field completed. Bypassing Email Subscription"
        head :forbidden
      end
    end

    def ip_reputation_check
      return true unless Rails.env.production?

      unless IpReputation.valid?(request.remote_ip)
        Rails.logger.warn "IP reputation check failed. Bypassing signup"
        head :forbidden
      end
    end

    def form_complete_time_check
      head :forbidden if params[:rendered_at].blank?

      timestamp = params[:rendered_at].to_i
      form_complete_time = Time.now.to_i - timestamp

      if form_complete_time < 5.seconds
        Rails.logger.warn "Form completed too quickly. Bypassing signup"
        head :forbidden
      end
    end

    def email_subscriber_params
      params.require(:email_subscriber).permit(:email)
    end
end
