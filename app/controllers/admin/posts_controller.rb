class Admin::PostsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @posts = pagy(
      Post.joins(blog: :user)
          .where(users: { discarded_at: nil })
          .includes(blog: :user)
          .order(published_at: :desc),
      limit: 15
    )
  end
end
