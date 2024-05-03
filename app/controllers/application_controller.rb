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

    def redirect_home
      redirect_to root_url(host: request.host, protocol: request.protocol, port: request.port), allow_other_host: true
    end

  private

    def domain_check
      redirect_home if custom_domain_request?
    end
end
