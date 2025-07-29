class Blogs::EmailSubscribers::UnsubscribesController < ApplicationController
  before_action :load_subscriber
  skip_before_action :domain_check
  skip_before_action :verify_authenticity_token, only: [ :one_click ]

  def show
  end

  def create
    unsubscribe_subscriber
  end

  def one_click
    unsubscribe_subscriber
  end

  private

    def unsubscribe_subscriber
      @subscriber.destroy!
      render :show
    end

    def load_subscriber
      if @subscriber = EmailSubscriber.find_by(token: params[:token])
        @blog = @subscriber.blog
      else
        redirect_to root_path, alert: "No email subscription found" and return
      end
    end
end
