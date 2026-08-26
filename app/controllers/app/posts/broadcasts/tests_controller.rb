class App::Posts::Broadcasts::TestsController < App::BaseController
  rate_limit to: 5, within: 5.minutes, only: :create, by: -> { Current.user.id }, with: :limit_reached

  def create
    @post = @blog.posts.kept.find_by!(token: params[:post_token])

    if @post.individually_sendable?
      PostDigestMailer.with(post: @post, email: Current.user.email).test_individual.deliver_later
      redirect_to edit_app_post_path(@post), notice: "Test email sent to #{Current.user.email}."
    else
      redirect_to edit_app_post_path(@post), alert: "Cannot send a test for this post."
    end
  end

  private

    def limit_reached
      @post = @blog.posts.kept.find_by!(token: params[:post_token])
      redirect_to edit_app_post_path(@post), alert: "Too many test emails. Please wait a few minutes."
    end
end
