class Admin::VerificationEmailsController < AdminController
  def create
    @user = User.find(params[:user_id])
    AccountVerificationMailer.with(user: @user).verify.deliver_later

    redirect_to admin_user_path(@user), notice: "Verification email has been resent to #{@user.email}."
  end
end
