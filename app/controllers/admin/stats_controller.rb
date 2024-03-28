class Admin::StatsController < AdminController
  include Pagy::Backend

  def index
    #@pagy, @users = pagy(User.all.includes(:posts).order(created_at: :desc), items: 15)
    @pagy, @users = pagy(User.select('users.*, COUNT(posts.id) AS posts_count')
                          .left_outer_joins(:posts)
                          .group('users.id')
                          .order(created_at: :desc), items: 15)
  end
end
