class Admin::StatsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @blogs = pagy(Blog.select("blogs.*, COUNT(posts.id) AS posts_count")
                          .left_outer_joins(:posts)
                          .group("blogs.id")
                          .order(created_at: :desc), limit: 15)
  end
end
