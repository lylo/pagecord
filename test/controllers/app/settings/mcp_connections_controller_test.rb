require "test_helper"

class App::Settings::McpConnectionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "lists and disconnects an app" do
    login_as users(:joel)

    get app_settings_api_path
    assert_select "div", text: /Claude\s+connected/

    assert_difference -> { McpConnection.count }, -1 do
      delete app_settings_mcp_connection_path(mcp_connections(:joel_claude))
    end
    assert_redirected_to app_settings_api_path
  end
end
