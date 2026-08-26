class App::Posts::BroadcastsController < App::BaseController
  def create
    @post = @blog.posts.kept.find_by!(token: params[:post_token])

    if @post.individually_sendable?
      @post.send_to_subscribers!
      redirect_to edit_app_post_path(@post), notice: "Sent to subscribers."
    else
      redirect_to edit_app_post_path(@post), alert: "Cannot send this post to subscribers."
    end
  end
end
