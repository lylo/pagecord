module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :expire_legacy_session_cookie
    before_action :authenticate
    helper_method :logged_in?
  end

  private

  def authenticate
    return unless DomainConstraints.default_domain?(request)
    return if session[:user_id].blank?

    if user = User.kept.find_by(id: session[:user_id])
      Current.user = user
    end
  end

  def logged_in?
    Current.user.present?
  end

  def sign_in(user)
    Rails.logger.info "Signing in #{user.id}"

    # A fresh session id on every sign in, so a session id planted beforehand
    # cannot be used afterwards. Attribution and the page that asked for a login
    # are carried over because both are captured before sign in.
    carried = session.to_hash.slice("signup_attribution", "return_to")
    reset_session
    carried.each { |key, value| session[key] = value }

    session[:user_id] = user.id
  end

  def sign_out
    reset_session
  end

  # Remove after June 2027, once all _pagecord_v2 cookies issued before the v3 rotation have expired.
  def expire_legacy_session_cookie
    return if cookies["_pagecord_v2"].blank?

    domain = Rails.application.config.x.domain
    return unless request.host == domain || request.host.end_with?(".#{domain}")

    cookies.delete("_pagecord_v2", domain: ".#{domain}", path: "/")
  end
end
