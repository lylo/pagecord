class App::PostsController < AppController
  include Pagy::Backend

  def index
    @pagy, @posts =  pagy(Current.user.posts.order(published_at: :desc), items: 15)
  end

  def destroy
    post = Current.user.posts.find(params[:id])
    post.destroy!

    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end
end
