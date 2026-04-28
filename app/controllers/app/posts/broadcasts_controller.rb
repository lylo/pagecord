class App::Posts::BroadcastsController < AppController
  rate_limit to: 5, within: 5.minutes, only: :test, by: -> { Current.user.id }, with: :test_limit_reached

  def create
    @post = Current.user.blog.posts.kept.find_by!(token: params[:post_token])

    if @post.individually_sendable?
      @post.send_to_subscribers!
      redirect_to edit_app_post_path(@post), notice: "Sent to subscribers."
    else
      redirect_to edit_app_post_path(@post), alert: "Cannot send this post to subscribers."
    end
  end

  def test
    @post = Current.user.blog.posts.kept.find_by!(token: params[:post_token])

    if @post.individually_sendable?
      PostDigestMailer.with(post: @post, email: Current.user.email).test_individual.deliver_later
      redirect_to edit_app_post_path(@post), notice: "Test email sent to #{Current.user.email}."
    else
      redirect_to edit_app_post_path(@post), alert: "Cannot send a test for this post."
    end
  end

  private

    def test_limit_reached
      @post = Current.user.blog.posts.kept.find_by!(token: params[:post_token])
      redirect_to edit_app_post_path(@post), alert: "Too many test emails. Please wait a few minutes."
    end
end
