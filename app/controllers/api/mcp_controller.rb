class Api::McpController < Api::BaseController
  PROTOCOL_VERSIONS = %w[ 2025-03-26 2025-06-18 2025-11-25 ].freeze

  TOOLS = [
    Mcp::Tools::ListPosts, Mcp::Tools::GetPost, Mcp::Tools::CreatePost, Mcp::Tools::UpdatePost, Mcp::Tools::DeletePost,
    Mcp::Tools::GetAppearance, Mcp::Tools::UpdateAppearance, Mcp::Tools::GetCustomCode, Mcp::Tools::UpdateCustomCode
  ].freeze

  before_action :require_mcp

  INSTRUCTIONS = <<~TEXT.squish
    Tools for managing one Pagecord blog. Post content is Markdown. New posts are drafts
    unless status is "published". Fetch a post with get_post before updating its content,
    because update_post replaces the whole body. Before writing CSS, fetch the blog's
    homepage (its url is in get_appearance) to see the markup; the classes are documented
    at https://help.pagecord.com/custom-css.
  TEXT

  def create
    if notification?
      head :accepted
    else
      render json: { jsonrpc: "2.0", id: message[:id] }.merge(response_to(message[:method]))
    end
  end

  private

    def message
      @message ||= request.request_parameters.deep_symbolize_keys
    end

    def message_params
      message[:params].is_a?(Hash) ? message[:params] : {}
    end

    def notification?
      message[:method].to_s.start_with?("notifications/")
    end

    def response_to(method)
      case method
      when "initialize" then result(server_description)
      when "ping" then result({})
      when "tools/list" then result(tools: TOOLS.map(&:definition))
      when "tools/call" then call_tool
      else error(-32601, "Method not found")
      end
    end

    def server_description
      requested = message_params[:protocolVersion]

      {
        protocolVersion: PROTOCOL_VERSIONS.include?(requested) ? requested : PROTOCOL_VERSIONS.last,
        capabilities: { tools: {} },
        serverInfo: { name: "pagecord", title: "Pagecord", version: "1.0.0" },
        instructions: INSTRUCTIONS
      }
    end

    def call_tool
      tool = TOOLS.find { it.tool_name == message_params[:name] }
      arguments = message_params.fetch(:arguments, {})

      if tool.nil?
        error(-32602, "Unknown tool: #{message_params[:name]}")
      elsif !arguments.is_a?(Hash)
        error(-32602, "Arguments must be an object")
      else
        result tool.call(Current.blog, arguments)
      end
    end

    def result(data)
      { result: data }
    end

    def error(code, message)
      { error: { code:, message: } }
    end

    def require_mcp
      raise ActiveRecord::RecordNotFound unless Rails.features.for(blog: Current.blog).enabled?(:mcp)
    end

    def authenticate
      authenticate_with_http_token do |token, _options|
        Current.blog = Blog.find_by_mcp_token(token)
      end

      unauthorized unless Current.blog
    end

    def unauthorized
      response.headers["WWW-Authenticate"] = %(Bearer resource_metadata="#{oauth_protected_resource_url(host: api_host)}")
      render json: { error: "invalid_token" }, status: :unauthorized
    end
end
