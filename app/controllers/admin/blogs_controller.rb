class Admin::BlogsController < AdminController
  include Pagy::Method

  def index
    @total_users = Blog.count
    @date_column = helpers.blogs_date_column

    blogs = Blog.select("blogs.*, COUNT(posts.id) AS posts_count, #{@date_column[:sql]} AS status_date")
                .left_outer_joins(:posts)
                .joins(:user)
                .left_outer_joins(user: :subscription)
                .group("blogs.id")
                .order("#{@date_column[:sql]} #{@date_column[:order] == :asc ? "ASC" : "DESC"} NULLS LAST")

    if params[:search].present?
      blogs = blogs.where("blogs.subdomain ILIKE ? OR users.email ILIKE ? OR subscriptions.paddle_customer_id ILIKE ? OR subscriptions.paddle_subscription_id ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    case params[:status]
    when "paid"
      blogs = blogs.where("subscriptions.plan IN (?) AND subscriptions.cancelled_at IS NULL AND subscriptions.next_billed_at > ?", [ "annual", "monthly" ], Time.current)
    when "comped"
      blogs = blogs.where("subscriptions.plan = ?", "complimentary")
    when "churning"
      blogs = blogs.where.not(subscriptions: { cancelled_at: nil }).where("subscriptions.next_billed_at > ?", Time.current)
    end

    @pagy, @blogs = pagy(blogs, limit: 15)
  end
end
