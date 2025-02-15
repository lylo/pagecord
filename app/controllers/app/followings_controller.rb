class App::FollowingsController < AppController
  include Pagy::Backend
  include ActionView::RecordIdentifier

  rescue_from Pagy::OverflowError, with: -> { redirect_to app_followings_path }

  def index
    @pagy, @followed_blogs = pagy(Current.user.followed_blogs, limit: 15)
  end

  def create
    @blog = Blog.find(params[:blog_id])

    begin
      Current.user.follow(@blog)
    rescue => e
      head :bad_request and return
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("#{dom_id(@blog)}-follow-button", partial: "blogs/follow_button", locals: { blog: @blog })
      end
    end
  end

  def destroy
    @blog = Blog.find(params[:blog_id])

    begin
      Current.user.unfollow(@blog)
    rescue => e
      head :bad_request and return
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("#{dom_id(@blog)}-follow-button", partial: "blogs/follow_button", locals: { blog: @blog })
      end
    end
  end
end
