class Admin::SpotlightExclusionsController < AdminController
  def create
    user = User.find(params[:user_id])
    blog = params[:blog_id] ? user.blogs.find(params[:blog_id]) : user.blog
    blog.exclude_from_spotlight
    redirect_to admin_user_path(user), notice: "Blog excluded from spotlight"
  end

  def destroy
    user = User.find(params[:user_id])
    blog = params[:blog_id] ? user.blogs.find(params[:blog_id]) : user.blog
    blog.include_in_spotlight
    redirect_to admin_user_path(user), notice: "Blog included in spotlight"
  end
end
