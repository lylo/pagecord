class Blogs::EmailSubscribers::ConfirmationsController < Blogs::BaseController
  before_action :load_subscriber
  skip_before_action :load_blog, :validate_user, :enforce_custom_domain

  def show
    @subscriber.confirm! unless @subscriber.confirmed?
  end

  private

    def load_subscriber
      @subscriber = EmailSubscriber.find_by!(token: params[:token])
      @blog = @subscriber.blog
      Current.blog = @blog
      @user = @blog.user
    end
end
