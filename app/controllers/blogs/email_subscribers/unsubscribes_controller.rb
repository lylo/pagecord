class Blogs::EmailSubscribers::UnsubscribesController < ApplicationController
  before_action :load_subscriber
  skip_before_action :domain_check
  skip_before_action :verify_authenticity_token, only: [ :one_click ]
  around_action :set_locale

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
        redirect_to root_path, alert: I18n.t("email_subscribers.unsubscribes.not_found") and return
      end
    end

    def set_locale(&block)
      I18n.with_locale(@blog&.locale || I18n.default_locale, &block)
    end
end
