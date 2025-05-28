module CustomDomainHelper
  def custom_domain_request?
    if Rails.env.test?
      alloweds_ip_addresses = [ "127.0.0.1" ]
      allowed_hosts = [ "lvh.me", "example.com" ]

      local_request = alloweds_ip_addresses.include?(request.host) ||
          allowed_hosts.any? { |host| request.host == host || request.host.end_with?(".#{host}") }

      !local_request
    else
      default_host = Rails.application.config.x.domain
      request.host != default_host && !request.host.end_with?(".#{default_host}")
    end
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
