require "test_helper"

class App::SettingsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should get index" do
    get app_settings_url
    assert_response :success
  end
end
