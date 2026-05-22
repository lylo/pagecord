class App::Posts::RestorationsController < AppController
  def create
    post = Current.user.blog.posts.discarded.find_by!(token: params[:post_token])
    post.undiscard!
    redirect_to app_posts_trash_path, notice: "Post was successfully restored"
  end
end
