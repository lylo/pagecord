class App::Settings::McpConnectionsController < App::BaseController
  def destroy
    @blog.mcp_connections.find(params[:id]).destroy
    redirect_to app_settings_api_path, notice: "Disconnected"
  end
end
