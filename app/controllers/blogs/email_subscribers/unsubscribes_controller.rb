class Blogs::EmailSubscribers::UnsubscribesController < Blogs::BaseController
  before_action :load_subscriber
  skip_before_action :load_blog, :validate_user, :enforce_custom_domain
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
        Current.blog = @blog
        @user = @blog.user
      else
        redirect_to root_path, alert: I18n.t("email_subscribers.unsubscribes.not_found") and return
      end
    end
end
