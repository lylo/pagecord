class App::Posts::TrashController < AppController
  def index
    @trashed_posts = Current.user.blog.posts.discarded.order(discarded_at: :desc)
  end

  def destroy
    post = Current.user.blog.posts.discarded.find_by!(token: params[:token])
    post.undiscard!
    redirect_to app_posts_trash_index_path, notice: "Post was successfully restored"
  end
end
