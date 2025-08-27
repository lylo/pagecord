require "test_helper"

class App::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:vivian)
    login_as @user
  end

  test "should get index" do
    get app_analytics_path
    assert_response :success
  end

  test "should get index with day view" do
    get app_analytics_path(view_type: "day", date: "2024-01-01")
    assert_response :success
  end

  test "should get index with month view" do
    get app_analytics_path(view_type: "month", date: "2024-01")
    assert_response :success
  end

  test "should get index with year view" do
    get app_analytics_path(view_type: "year", date: "2024")
    assert_response :success
  end
end
