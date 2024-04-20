class AdminController < ApplicationController
  layout "admin"

  include Authorization

  before_action :require_admin

  def index
    redirect_to admin_stats_path
  end

  private

    def require_admin
      redirect_to root_path unless Current.user.is_admin?
    end
end
