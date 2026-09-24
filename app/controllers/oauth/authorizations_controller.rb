class Oauth::AuthorizationsController < App::BaseController
  layout "sessions"

  before_action :set_client
  before_action :require_premium, only: :create

  def new
  end

  def create
    if params[:decision] == "allow"
      connection = @user.blogs.find(params[:blog_id]).mcp_connections.new(
        client_id: params[:client_id], client_name: @client.name,
        redirect_uri: params[:redirect_uri], code_challenge: params[:code_challenge]
      )
      redirect_to_client code: connection.issue_code!
    else
      redirect_to_client error: "access_denied"
    end
  end

  private

    def require_login
      session[:return_to] = request.fullpath unless Current.user
      super
    end

    def set_client
      @client = Oauth::Client.find(params[:client_id])

      unless @client&.redirect_uri_allowed?(params[:redirect_uri]) && params[:response_type] == "code" &&
          params[:code_challenge].present? && params[:code_challenge_method] == "S256"
        render plain: "This connection request is invalid. Please try connecting again from the app.", status: :unprocessable_entity
      end
    end

    def require_premium
      head :forbidden unless @user.has_premium_access?
    end

    def redirect_to_client(**result)
      uri = URI.parse(params[:redirect_uri])
      uri.query = [ uri.query, result.merge(state: params[:state].presence).compact.to_query ].compact_blank.join("&")
      redirect_to uri.to_s, allow_other_host: true
    end
end
