class AppController < ApplicationController
  layout "app"

  include Authorization

  before_action :load_user, :onboarding_check

  private

    def load_user
      @user = Current.user
      @blog = @user.blog
      Current.blog = @blog
    end

    def onboarding_check
      unless @user&.onboarding_complete?
        redirect_to app_onboarding_path
      end
    end
end
