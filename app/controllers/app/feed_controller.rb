class App::FeedController < AppController
  include Pagy::Backend

  skip_before_action :require_login, :load_user, only: [ :private_rss ]

  before_action :require_token, only: [ :private_rss ]

  def index
    followed_blog_ids = @user.followed_blogs.pluck(:followed_id)
    @posts = Post.where(blog_id: followed_blog_ids).order(published_at: :desc)

    @pagy, @posts = pagy(@posts)
  end

  def private_rss
    followed_blog_ids = @user.followed_blogs.pluck(:followed_id)
    @posts = Post.where(blog_id: followed_blog_ids).order(published_at: :desc).limit(30)

    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  private

    def require_token
      full_token = "#{params[:token]}@post.pagecord.com"
      @user = User.joins(:blog).find_by(blog: { delivery_email: full_token })
      head :unauthorized unless @user
    end
end
