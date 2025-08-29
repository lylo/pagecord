class AdminController < AppController
  layout "admin"

  before_action :require_admin

  def index
    redirect_to admin_blogs_path
  end

  private

    def require_admin
      redirect_to root_path unless Current.user.admin?
    end
end
