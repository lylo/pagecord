class AdminController < ApplicationController
  layout "admin"

  include Authorization

  before_action :require_admin

  def index
    redirect_to admin_stats_path
  end

  private

    ADMIN_USERS = %w[olly pagecord]

    def require_admin
      admin = if Rails.env.production?
        ADMIN_USERS.include? Current.user.username
      else
        Current.user.username == "joel"
      end

      redirect_to root_path unless admin
    end
end
