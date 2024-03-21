module Authorization
  extend ActiveSupport::Concern

  class Error < StandardError; end

  included do
    before_action :require_login
  end

  private

  def require_login
    return if Current.user

    flash[:error] = "You must log in to see this page"
    redirect_to login_path
  end
end
