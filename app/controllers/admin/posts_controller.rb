class Admin::PostsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @posts = pagy(Post.all.includes(:user).order(created_at: :desc), items: 15)
  end
end
