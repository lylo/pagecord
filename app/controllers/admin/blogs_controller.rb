class Admin::BlogsController < AdminController
  include Pagy::Backend

  def index
    @total_users = Blog.count

    blogs = Blog.select("blogs.*, COUNT(posts.id) AS posts_count")
                .left_outer_joins(:posts)
                .joins(:user)
                .left_outer_joins(user: :subscription)
                .group("blogs.id")
                .order(created_at: :desc)

    if params[:search].present?
      blogs = blogs.where("blogs.subdomain ILIKE ? OR users.email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:status].present?
      case params[:status]
      when "paid"
        blogs = blogs.where("subscriptions.plan = ? AND subscriptions.cancelled_at IS NULL AND subscriptions.next_billed_at > ?", "annual", Time.current)
      when "comped"
        blogs = blogs.where("subscriptions.plan = ?", "complimentary")
      end
    end

    @pagy, @blogs = pagy(blogs, limit: 15)
  end
end
