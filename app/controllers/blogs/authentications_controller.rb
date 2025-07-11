class Blogs::AuthenticationsController < Blogs::BaseController
  layout "blog_authentication"
  skip_before_action :check_private_blog_access, only: [ :show, :create ]

  def show
    # Redirect to blog home if already authenticated or if blog is not private
    if !@blog.is_private? || authenticated?
      redirect_to redirect_after_authentication
    end
  end

  def create
    if @blog.verify_password(params[:password])
      # Store the password digest in the session
      session["blog_auth_#{@blog.id}"] = @blog.password_digest
      redirect_to redirect_after_authentication, notice: "Welcome to #{@blog.display_name}!"
    else
      flash.now[:alert] = "Invalid password. Please try again."
      render :show, status: :unprocessable_entity
    end
  end

  private

  def authenticated?
    stored_digest = session["blog_auth_#{@blog.id}"]
    stored_digest && @blog.password_digest == stored_digest
  end

  def redirect_after_authentication
    return_to = session.delete(:return_to)
    # Only redirect to paths on the same domain to prevent open redirects
    if return_to.present? && return_to.start_with?("/")
      return_to
    else
      blog_posts_path
    end
  end
end
