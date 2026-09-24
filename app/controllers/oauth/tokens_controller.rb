class Oauth::TokensController < ActionController::API
  def create
    return render_error("unsupported_grant_type") unless params[:grant_type] == "authorization_code"

    connection = McpConnection.find_by_code(params[:code])

    if connection && connection.client_id == params[:client_id] && connection.redirect_uri == params[:redirect_uri] && connection.verifies?(params[:code_verifier])
      response.headers["Cache-Control"] = "no-store"
      render json: { access_token: connection.issue_token!, token_type: "bearer", scope: "blog" }
    else
      render_error "invalid_grant"
    end
  end

  private

    def render_error(error)
      render status: :bad_request, json: { error: error }
    end
end
