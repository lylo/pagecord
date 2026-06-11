class App::Posts::TrashController < AppController
  def show
    @trashed_posts = @blog.posts.discarded.order(discarded_at: :desc)
  end

  def create
    post = @blog.posts.kept.find_by!(token: params[:post_token])
    post.discard!
    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end

  def destroy
    @blog.posts.discarded.destroy_all
    redirect_to app_posts_trash_path, notice: "Trash was successfully emptied"
  end
end
