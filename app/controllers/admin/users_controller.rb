class Admin::UsersController < AdminController
  def show
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])

    if @user.subscribed?
      flash[:notice] = "You can't discard a premium user"
    else
      if params[:spam]
        flash[:notice] = "User was marked as spam and discarded"
        DestroyUserJob.perform_now(@user.id, spam: true)
      else
        flash[:notice] = "User was successfully discarded"
        DestroyUserJob.perform_now(@user.id)
      end
    end

    redirect_to admin_stats_path
  end
end
