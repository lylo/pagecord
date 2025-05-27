module CustomDomainHelper
  def custom_domain_request?
    default_host = Rails.application.config.x.domain
    if Rails.env.production?
      !request.host.include?(default_host)
    elsif Rails.env.test?
      !request.host.include?(default_host)
    else
      # In development, only consider it a custom domain if it's not our development domains
      local_domain_pattern = /\A([^.]+\.)*localhost\z/
      !request.host.match?(local_domain_pattern)
    end
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
