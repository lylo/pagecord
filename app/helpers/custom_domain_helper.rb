module CustomDomainHelper
  def custom_domain_request?
    if Rails.env.production?
      request.host != Rails.application.config.x.domain
    elsif Rails.env.test?
      request.host !~ /\.example\.com/ && request.host != "127.0.0.1"  # 127.0.0.1 used by Capybara
    else
      ![ "localhost", "ant-evolved-equally.ngrok-free.app" ].include?(request.host)
    end
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
