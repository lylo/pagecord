class Admin::PostsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @posts = pagy(Post.joins(:user).where(users: { discarded_at: nil }).includes(:user).order(created_at: :desc), items: 15)
  end
end
