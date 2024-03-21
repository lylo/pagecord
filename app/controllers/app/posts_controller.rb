class App::PostsController < AppController
  include Pagy::Backend

  before_action :load_user

  def index
    @pagy, @posts =  pagy(Current.user.posts)
  end

  def destroy
    post = Current.user.posts.find(params[:id])
    post.destroy!

    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end

  private

    def load_user
      @user = Current.user
    end
end
