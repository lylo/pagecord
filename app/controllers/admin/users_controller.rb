class Admin::UsersController < AdminController
  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
    @user.build_blog
  end

  def create
    @user = User.new(user_params)
    if @user.save
      AccountVerificationMailer.with(user: @user).verify.deliver_later
      redirect_to admin_users_path, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
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

  def restore
    @user = User.find(params[:id])

    if @user.discarded?
      @user.undiscard!
      flash[:notice] = "User was successfully restored"
    end

    redirect_to admin_stats_path
  end

  private

  def user_params
    params.require(:user).permit(:email, blog_attributes: [ :subdomain ])
  end
end
