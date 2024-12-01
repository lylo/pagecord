class Admin::PostsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @posts = pagy(Post.joins(:user).where(users: { discarded_at: nil }).includes(:user).order(published_at: :desc), limit: 15)
  end
end
