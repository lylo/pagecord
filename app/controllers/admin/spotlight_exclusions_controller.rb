class Admin::SpotlightExclusionsController < AdminController
  def create
    user = User.find(params[:user_id])
    user.blog.exclude_from_spotlight
    redirect_to admin_user_path(user), notice: "Blog excluded from spotlight"
  end

  def destroy
    user = User.find(params[:user_id])
    user.blog.include_in_spotlight
    redirect_to admin_user_path(user), notice: "Blog included in spotlight"
  end
end
