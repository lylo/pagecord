class App::Posts::BroadcastsController < AppController
  def create
    @post = Current.user.blog.posts.kept.find_by!(token: params[:post_token])

    if @post.individually_sendable? && Current.user.blog.individual?
      @post.send_to_subscribers!
      redirect_to edit_app_post_path(@post), notice: "Sent to subscribers."
    else
      redirect_to edit_app_post_path(@post), alert: "Cannot send this post to subscribers."
    end
  end
end
