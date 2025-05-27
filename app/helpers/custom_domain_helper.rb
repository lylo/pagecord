module CustomDomainHelper
  def custom_domain_request?
    default_host = Rails.application.config.x.domain
    !request.host.include?(default_host)
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
