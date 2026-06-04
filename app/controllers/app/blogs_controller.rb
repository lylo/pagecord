class App::BlogsController < AppController
  before_action :require_subscription, only: [ :new, :create ]

  def index
    @blogs = Current.user.blogs.order(:created_at)
  end

  def new
    @new_blog = Current.user.blogs.build
  end

  def create
    @new_blog = Current.user.blogs.build(blog_params)

    if @new_blog.save
      session[:current_blog_id] = @new_blog.id
      redirect_to app_root_path, notice: "Blog created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    blog = Current.user.all_blogs.find(params[:id])

    if blog.discarded?
      display_name = blog.display_name
      blog.destroy!
      redirect_to app_blogs_trash_path, notice: "#{display_name} was permanently deleted"
      return
    end

    if Current.user.blogs.count <= 1
      redirect_to app_blogs_path, alert: "You must have at least one blog"
      return
    end

    blog.discard!

    if session[:current_blog_id].to_s == blog.id.to_s
      session[:current_blog_id] = Current.user.blogs.order(:created_at).first.id
    end

    redirect_to app_blogs_path, notice: "#{blog.display_name} was moved to trash"
  end

  def switch
    blog = Current.user.blogs.find(params[:id])
    session[:current_blog_id] = blog.id
    redirect_to app_root_path
  end

  private

    def require_subscription
      redirect_to app_blogs_path, alert: "Subscribe to create another blog" unless Current.user.subscribed?
    end

    def blog_params
      params.require(:blog).permit(:subdomain, :title)
    end
end
