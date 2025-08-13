class AppController < ApplicationController
  layout "app"

  include Authorization

  before_action :load_user, :onboarding_check
  around_action :set_timezone, if: -> { Current.user.present? }

  rescue_from ActiveRecord::RecordNotFound, with: :render_app_not_found
  rescue_from ActionController::UnpermittedParameters, with: :render_app_unacceptable  
  rescue_from StandardError, with: :render_app_internal_error

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

    def render_app_unacceptable
      render "errors/unacceptable", status: 422
    end

    def render_app_internal_error
      render "errors/internal_error", status: 500
    end
end
