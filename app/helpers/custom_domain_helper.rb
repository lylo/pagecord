module CustomDomainHelper
  def custom_domain_request?
    if Rails.env.production?
      request.host != "pagecord.com"
    elsif Rails.env.test?
      request.host !~ /\.example\.com/ && request.host != "127.0.0.1"  # 127.0.0.1 used by Capybara
    else
      request.host != "localhost"
    end
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
