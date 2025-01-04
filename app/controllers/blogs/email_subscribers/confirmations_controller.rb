class Blogs::EmailSubscribers::ConfirmationsController < ApplicationController
  before_action :load_subscriber
  skip_before_action :domain_check

  def show
    @subscriber.confirm! unless @subscriber.confirmed?
  end

  private

    def load_subscriber
      @subscriber = EmailSubscriber.find_by!(token: params[:token])
      @blog = @subscriber.blog
    end
end
