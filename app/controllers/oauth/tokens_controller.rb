class Oauth::TokensController < ActionController::API
  def create
    return render_error("unsupported_grant_type") unless params[:grant_type] == "authorization_code"

    token = McpConnection.exchange(params[:code], client_id: params[:client_id], redirect_uri: params[:redirect_uri], code_verifier: params[:code_verifier])

    if token
      response.headers["Cache-Control"] = "no-store"
      render json: { access_token: token, token_type: "bearer", scope: "blog" }
    else
      render_error "invalid_grant"
    end
  end

  private

    def render_error(error)
      render status: :bad_request, json: { error: error }
    end
end
