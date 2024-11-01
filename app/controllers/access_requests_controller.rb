class AccessRequestsController < ApplicationController
  def verify
    if access_request = AccessRequest.active.pending.find_by(token_digest: params[:token])
      @user = access_request.user
      @user.verify!
      access_request.accept!

      sign_in @user

      redirect_to app_posts_url
    else
      redirect_to root_path
    end
  end
end
