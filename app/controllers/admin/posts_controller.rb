class Admin::PostsController < AdminController
  include Pagy::Method

  def index
    scope = Post.visible.joins(blog: :user)
                .where(users: { discarded_at: nil })
                .includes(blog: :user)
                .order(published_at: :desc)

    case params[:period]
    when "today"
      scope = scope.where("posts.published_at >= ?", Date.current.beginning_of_day)
    when "week"
      scope = scope.where("posts.published_at >= ?", 7.days.ago.beginning_of_day)
    end

    @pagy, @posts = pagy(scope, limit: 15)
  end
end
