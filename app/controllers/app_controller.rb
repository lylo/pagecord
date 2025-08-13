class AppController < ApplicationController
  layout "app"

  include Authorization

  before_action :load_user, :onboarding_check
  around_action :set_timezone, if: -> { Current.user.present? }

  rescue_from ActiveRecord::RecordNotFound, with: :render_app_not_found

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

    def set_timezone(&block)
      Time.use_zone(Current.user.timezone, &block)
    end

    def render_app_not_found
      render "errors/not_found", status: 404
    end
end
