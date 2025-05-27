module CustomDomainHelper
  def custom_domain_request?
    if Rails.env.production?
      request.host != Rails.application.config.x.domain
    elsif Rails.env.test?
      request.host !~ /\.example\.com/ && request.host != "127.0.0.1"  # 127.0.0.1 used by Capybara
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
