class Admin::BaseController < App::BaseController
  layout "admin"

  before_action :require_admin

  private

    def require_admin
      redirect_to root_path unless Current.user.admin?
    end
end
