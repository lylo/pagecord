class App::FeedController < AppController
  include Pagy::Backend

  skip_before_action :require_login, :load_user, only: [:private_rss]

  before_action :require_token, only: [:private_rss]

  def index
    followed_users_ids = @user.followed_users.pluck(:followed_id)

    @pagy, @posts = pagy(Post.where(user_id: followed_users_ids).order(created_at: :desc), items: 15)
  end

  def private_rss
    followed_users_ids = @user.followed_users.pluck(:followed_id)
    @posts = Post.where(user_id: followed_users_ids).order(created_at: :desc).limit(30)

    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  private

    def require_token
      full_token = "#{params[:token]}@post.pagecord.com"
      @user = User.find_by(delivery_email: full_token)
      head :unauthorized unless @user
    end
end
