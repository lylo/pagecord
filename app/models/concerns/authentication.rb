module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
    helper_method :logged_in?
  end

  private

  def authenticate
    if user = User.find_by(id: session[:user_id])
      Rails.logger.info "Found authenticated user #{user.id}}"
      Current.user = user
    else
      Rails.logger.info "No authenticated user found"
    end
  end

  def logged_in?
    Current.user.present?
  end

  def sign_in(user)
    Rails.logger.info "Signing in #{user.id}"
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end
end
