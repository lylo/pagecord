class Oauth::MetadataController < ActionController::API
  include RoutingHelper

  def authorization_server
    render json: {
      issuer: issuer,
      authorization_endpoint: oauth_authorization_url(host: app_host),
      token_endpoint: oauth_token_url(host: app_host),
      registration_endpoint: oauth_registration_url(host: app_host),
      response_types_supported: [ "code" ],
      grant_types_supported: [ "authorization_code" ],
      code_challenge_methods_supported: [ "S256" ],
      token_endpoint_auth_methods_supported: [ "none" ],
      scopes_supported: [ "blog" ]
    }
  end

  def protected_resource
    render json: {
      resource: mcp_endpoint_url,
      authorization_servers: [ issuer ],
      bearer_methods_supported: [ "header" ],
      scopes_supported: [ "blog" ]
    }
  end

  private

    def issuer
      root_url(host: app_host).chomp("/")
    end

    def app_host
      Rails.application.config.x.domain
    end
end
