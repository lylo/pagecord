class Admin::SubscriptionsController < AdminController
  def update
    user = User.find(params[:user_id])

    user.subscription.extend_to(params[:next_billed_at])
    redirect_to admin_user_path(user), notice: "Subscription extended to #{user.subscription.next_billed_at.strftime('%B %d, %Y')}"
  end
end
