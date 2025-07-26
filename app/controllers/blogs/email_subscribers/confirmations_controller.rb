class Blogs::EmailSubscribers::ConfirmationsController < ApplicationController
  before_action :load_subscriber
  skip_before_action :domain_check
  around_action :set_locale

  def show
    @subscriber.confirm! unless @subscriber.confirmed?
  end

  private

    def load_subscriber
      @subscriber = EmailSubscriber.find_by!(token: params[:token])
      @blog = @subscriber.blog
    end

    def set_locale(&block)
      I18n.with_locale(@blog.locale, &block)
    end
end
