module DomainConstraints
  def self.default_domain?(request)
    if Rails.env.test?
      [ "localhost", "lvh.me", "example.com" ].include?(request.host)
    else
      request.host == Rails.application.config.x.domain
    end
  end

  def self.api_domain?(request)
    if Rails.env.test?
      request.host == "api.example.com"
    elsif Rails.env.production?
      request.host == "api.#{Rails.application.config.x.domain}"
    else
      request.host.start_with?("api.")
    end
  end
end
