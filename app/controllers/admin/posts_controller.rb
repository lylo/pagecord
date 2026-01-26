class Admin::PostsController < AdminController
  include Pagy::Method

  def index
    @pagy, @posts = pagy(
      Post.visible.joins(blog: :user)
          .where(users: { discarded_at: nil })
          .includes(blog: :user)
          .order(published_at: :desc),
      limit: 15
    )
  end
end
