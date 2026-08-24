class AccessRequests::VerificationsController < ApplicationController
  include PricingHelper

  def show
    access_request = AccessRequest.login.active.pending.find_by(token_digest: params[:token]) ||
                     AccessRequest.login.active.recently_accepted.find_by(token_digest: params[:token])
    return redirect_to root_path unless access_request

    @user = access_request.user

    if !@user.verified? && access_request.pending?
      @user.verify!

      WelcomeMailer.with(user: @user, price: localised_price).welcome_email.deliver_later
      MarketingAutomation::AddContactJob.perform_later(@user.id)
    end

    access_request.accept!

    sign_in @user

    redirect_to app_posts_path
  end
end
