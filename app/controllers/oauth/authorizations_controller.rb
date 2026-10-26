class Oauth::AuthorizationsController < App::BaseController
  layout "letter"

  before_action :set_client
  before_action :require_premium, only: :create

  def new
    @denial_url = client_url(error: "access_denied")
  end

  def create
    connection = @user.blogs.find(params[:blog_id]).mcp_connections.find_or_initialize_by(client_id: params[:client_id])
    connection.assign_attributes(client_name: @client.name, redirect_uri: params[:redirect_uri], code_challenge: params[:code_challenge])

    redirect_to client_url(code: connection.issue_code!), allow_other_host: true
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

    def client_url(**result)
      uri = URI.parse(params[:redirect_uri])
      uri.query = [ uri.query, result.merge(state: params[:state].presence).compact.to_query ].compact_blank.join("&")
      uri.to_s
    end
end
