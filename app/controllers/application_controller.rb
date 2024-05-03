class ApplicationController < ActionController::Base
  include Authentication

  before_action :domain_check

  protected

    def custom_domain_request?
      if Rails.env.production?
        request.host != "pagecord.com"
      elsif Rails.env.test?
        request.host !~ /\.example\.com/
      else
        request.host != "localhost"
      end
    end

    def redirect_home_with_forbidden
      redirect_to "https://pagecord.com", status: :forbidden, allow_other_host: true
    end

  private

    def domain_check
      redirect_home_with_forbidden if custom_domain_request?
    end
end
