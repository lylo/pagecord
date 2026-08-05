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

    if user = User.kept.find_by(id: session[:user_id])
      Rails.logger.info "Authenticated #{user.id}"
      Current.user = user
    end
  end

  def logged_in?
    Current.user.present?
  end

  def sign_in(user)
    Rails.logger.info "Signing in #{user.id}"

    # A fresh session id on every sign in, so a session id planted beforehand
    # cannot be used afterwards. Attribution is carried over because it is
    # captured before signup completes.
    attribution = session[:signup_attribution]
    reset_session
    session[:signup_attribution] = attribution if attribution.present?

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
