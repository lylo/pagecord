class Admin::StatsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @users = pagy(User.all.order(created_at: :desc), items: 15)
  end
end
