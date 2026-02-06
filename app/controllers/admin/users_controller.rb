class Admin::UsersController < AdminController
  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
    @user.blogs.build
  end

  def create
    @user = User.new(user_params)
    if @user.save
      AccountVerificationMailer.with(user: @user).verify.deliver_later
      redirect_to admin_user_path(@user), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])

    if params[:spam]
      flash[:notice] = "User was marked as spam and discarded"
      DestroyUserJob.perform_now(@user.id, spam: true)
    else
      flash[:notice] = "User was successfully discarded"
      DestroyUserJob.perform_now(@user.id)
    end

    redirect_to admin_blogs_path
  end

  def restore
    @user = User.find(params[:id])

    if @user.discarded?
      @user.undiscard!
      flash[:notice] = "User was successfully restored"
    end

    redirect_to admin_blogs_path
  end

  private

    def user_params
      params.require(:user).permit(:email, :trial_ends_at, blogs_attributes: [ :subdomain ])
    end
end
