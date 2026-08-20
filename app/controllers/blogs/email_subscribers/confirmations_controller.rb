class Blogs::EmailSubscribers::ConfirmationsController < Blogs::BaseController
  before_action :load_subscriber, :set_locale
  skip_before_action :load_blog, :validate_user, :enforce_custom_domain, :require_blog_access

  def show
    @subscriber.confirm! unless @subscriber.confirmed?
  end

  private

    def load_subscriber
      if @subscriber = EmailSubscriber.find_by(token: params[:token])
        @blog = @subscriber.blog
        Current.blog = @blog
        @user = @blog.user
      else
        redirect_to root_path
      end
    end
end
