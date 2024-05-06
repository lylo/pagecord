class ApplicationController < ActionController::Base
  include Authentication, CustomDomainHelper

  before_action :domain_check

  protected

    def redirect_home
      redirect_to root_url(host: request.host, protocol: request.protocol, port: request.port), allow_other_host: true
    end

  private

    def domain_check
      redirect_home if custom_domain_request?
    end
end
