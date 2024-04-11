class ApplicationController < ActionController::Base
  include Authentication

  before_action :redirect_if_invalid_domain

  private

  def redirect_if_invalid_domain
    custom_domain_request = if Rails.env.production?
        request.host != "pagecord.com"
      else
        false
      end

    if custom_domain_request
      @user = User.find_by(custom_domain: request.host)
      redirect_to "https://pagecord.com", status: :moved_permanently, allow_other_host: true unless @user&.present?
    end
  end
end
