class Admin::Users::RestorationsController < Admin::BaseController
  def create
    user = User.find(params[:user_id])

    if user.discarded?
      user.undiscard!
      user.blogs.find_each(&:touch)
      flash[:notice] = "User was successfully restored"
    end

    redirect_to admin_users_path
  end
end
