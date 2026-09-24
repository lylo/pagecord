class Api::McpController < Api::BaseController
  include RoutingHelper

  TOOLS = [
    Mcp::ListPosts, Mcp::GetPost, Mcp::CreatePost, Mcp::UpdatePost, Mcp::DeletePost,
    Mcp::GetAppearance, Mcp::UpdateAppearance
  ].freeze

  INSTRUCTIONS = <<~TEXT.squish
    Tools for managing one Pagecord blog. Post content is Markdown. New posts are drafts
    unless status is "published". Fetch a post with get_post before updating its content,
    because update_post replaces the whole body.
  TEXT

  def create
    status, _headers, body = transport.handle_request(request)

    if body.empty?
      head status
    else
      render json: body.first, status: status
    end
  end

  private

    def authenticate
      authenticate_with_http_token do |token, _options|
        Current.blog = Blog.find_by_api_key(token) || McpConnection.find_by_token(token)&.blog
      end

      unauthorized unless Current.blog
    end

    def unauthorized
      response.headers["WWW-Authenticate"] = %(Bearer resource_metadata="#{oauth_protected_resource_url(host: api_host)}")
      render json: { error: "invalid_token" }, status: :unauthorized
    end

    def transport
      MCP::Server::Transports::StreamableHTTPTransport.new(
        server,
        stateless: true,
        enable_json_response: true,
        dns_rebinding_protection: false,
        serve_subscriptions_listen: false
      )
    end

    def server
      MCP::Server.new(
        name: "pagecord",
        title: "Pagecord",
        version: "1.0.0",
        instructions: INSTRUCTIONS,
        tools: TOOLS,
        server_context: { blog: Current.blog }
      )
    end
end
