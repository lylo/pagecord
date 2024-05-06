module CustomDomainHelper
  def custom_domain_request?
    Rails.logger.info "request.host: #{request.host}"
    if Rails.env.production?
      request.host != "pagecord.com"
    elsif Rails.env.test?
      request.host !~ /\.example\.com/
    else
      request.host != "localhost"
    end
  end

  def default_domain_request?
    !custom_domain_request?
  end
end
