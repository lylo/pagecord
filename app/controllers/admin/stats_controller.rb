class Admin::StatsController < AdminController
  include Pagy::Backend

  def index
    @total_users = Blog.count

    blogs = Blog.select("blogs.*, COUNT(posts.id) AS posts_count")
                .left_outer_joins(:posts)
                .joins(:user)
                .group("blogs.id")
                .order(created_at: :desc)

    if params[:search].present?
      blogs = blogs.where("blogs.subdomain ILIKE ? OR users.email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @pagy, @blogs = pagy(blogs, limit: 15)
  end
end
