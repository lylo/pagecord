class AccessRequestsController < ApplicationController
  def verify
    if access_request = AccessRequest.active.pending.find_by(token_digest: params[:token])
      @user = access_request.user

      unless @user.verified?
        @user.verify!
        MarketingAutomation::AddContactJob.perform_later(@user.id)
      end

      access_request.accept!

      sign_in @user

      redirect_to app_posts_path
    else
      redirect_to root_path
    end
  end
end
