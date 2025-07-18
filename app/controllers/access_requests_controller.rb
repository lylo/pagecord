class AccessRequestsController < ApplicationController
  include PricingHelper

  def verify
    access_request = AccessRequest.active.pending.find_by(token_digest: params[:token]) ||
                     AccessRequest.active.recently_accepted.find_by(token_digest: params[:token])
    if access_request
      @user = access_request.user

      if !@user.verified? && access_request.pending?
        @user.verify!

        localized_price = localised_price
        WelcomeMailer.with(user: @user, price: localized_price).welcome_email.deliver_later

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
