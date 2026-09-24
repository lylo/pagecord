class Oauth::ClientsController < ActionController::API
  wrap_parameters false

  def create
    redirect_uris = Array(params[:redirect_uris])

    if redirect_uris.any? && redirect_uris.all? { Oauth::Client.redirect_uri_acceptable?(it) }
      client_name = params[:client_name].presence || "An app"

      render status: :created, json: {
        client_id: Oauth::Client.register(name: client_name, redirect_uris:),
        client_name: client_name,
        redirect_uris: redirect_uris,
        token_endpoint_auth_method: "none",
        grant_types: [ "authorization_code" ],
        response_types: [ "code" ]
      }
    else
      render status: :bad_request, json: { error: "invalid_redirect_uri" }
    end
  end
end
