class AccessRequestsController < ApplicationController

  def verify
    if access_request = AccessRequest.active.pending.find_by(token_digest: params[:token])
      @user = access_request.user
      @user.update!(verified: true)
      access_request.accept!

      sign_in @user

      # TODO redirect to new app controller when it's ready
      redirect_to user_posts_path(@user.username)
    else
      redirect_to root_path
    end
  end
end
