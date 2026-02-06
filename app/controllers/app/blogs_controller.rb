class App::BlogsController < AppController
  def index
    @blogs = Current.user.blogs.order(:created_at)
  end

  def new
    @blog = Current.user.blogs.build
  end

  def create
    @blog = Current.user.blogs.build(blog_params)
    if @blog.save
      session[:current_blog_id] = @blog.id
      redirect_to app_root_path, notice: "Blog created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    blog = Current.user.blogs.find(params[:id])

    if Current.user.blogs.count <= 1
      redirect_to app_blogs_path, alert: "You must have at least one blog"
      return
    end

    blog.discard!

    if session[:current_blog_id].to_s == blog.id.to_s
      session[:current_blog_id] = Current.user.blogs.order(:created_at).first.id
    end

    redirect_to app_blogs_path, notice: "Blog deleted"
  end

  def switch
    blog = Current.user.blogs.find(params[:id])
    session[:current_blog_id] = blog.id
    redirect_to app_root_path
  end

  private

  def blog_params
    params.require(:blog).permit(:subdomain, :title)
  end
end
