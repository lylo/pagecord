class AdminController < ApplicationController
  layout "admin"

  include Authorization

  before_action :require_admin

  def index
    redirect_to admin_stats_path
  end

  private

    def require_admin
      admin = Rails.env.production? ? "pagecord" : "joel"
      unless Current.user.username == admin
        redirect_to root_path
      end
    end
end
