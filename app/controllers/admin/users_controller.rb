class Admin::UsersController < AdminController
  def destroy
    @user = User.find(params[:id])

    if @user == Current.user
      flash[:notice] = "You can't discard yourself"
    elsif @user.subscribed?
      flash[:notice] = "You can't discard a premium user"
    else
      flash[:notice] = "User was successfully discarded"
      DestroyUserJob.perform_now(@user.id)
    end

    redirect_to admin_stats_path
  end
end
