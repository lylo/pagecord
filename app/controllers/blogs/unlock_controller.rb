class Blogs::UnlockController < Blogs::BaseController
  skip_before_action :require_blog_password
  rate_limit to: 10, within: 1.minute, only: :create

  def new
    redirect_to "/" unless @blog.password_protected?
  end

  def create
    if @blog.authenticate(params[:password])
      cookies.encrypted[:blog_unlock] = { value: @blog.password_digest, expires: 30.days, httponly: true }
      redirect_to safe_return_to
    else
      flash.now[:alert] = "Incorrect password"
      render :new, status: :unprocessable_entity
    end
  end

  private

    def safe_return_to
      path = params[:return_to].to_s
      path.start_with?("/") && !path.start_with?("//") ? path : "/"
    end
end
