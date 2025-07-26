class Blogs::EmailSubscribers::UnsubscribesController < ApplicationController
  before_action :load_subscriber
  skip_before_action :domain_check

  def show
  end

  def create
    @subscriber.destroy!
    render :show
  end

  private

    def load_subscriber
      if @subscriber = EmailSubscriber.find_by(token: params[:token])
        @blog = @subscriber.blog
      else
        redirect_to root_path, alert: I18n.t("email_subscribers.unsubscribes.not_found") and return
      end
    end
end
