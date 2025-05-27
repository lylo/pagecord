module CustomDomainHelper
  def custom_domain_request?
    puts "custom_domain_request? called"
    default_host = Rails.application.config.x.domain
    puts "Default host: #{default_host}"
    puts "Request host: #{request.host}"
    custom = !request.host.include?(default_host) && request.host != "127.0.0.1" && !request.host.include?("localhost")
    puts "Is custom domain request? #{custom}"
    custom
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
