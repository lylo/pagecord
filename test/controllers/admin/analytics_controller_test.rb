require "test_helper"

class Admin::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @admin = users(:joel)
    login_as @admin
  end

  test "should get index" do
    get admin_analytics_path
    assert_response :success
  end

  test "should get index with month view" do
    get admin_analytics_path(view_type: "month", date: "2024-01")
    assert_response :success
    assert_equal "month", assigns(:view_type)
    assert_equal Date.parse("2024-01-01"), assigns(:date)
  end

  test "should get index with year view" do
    get admin_analytics_path(view_type: "year", date: "2024")
    assert_response :success
    assert_equal "year", assigns(:view_type)
    assert_equal Date.parse("2024-01-01"), assigns(:date)
  end

  test "should default to month view when no view_type specified" do
    get admin_analytics_path
    assert_response :success
    assert_equal "month", assigns(:view_type)
    assert_equal Date.current.beginning_of_month, assigns(:date)
  end

  test "should handle invalid date gracefully" do
    get admin_analytics_path(view_type: "month", date: "invalid")
    assert_response :success
    assert_equal "month", assigns(:view_type)
    assert_equal Date.current.beginning_of_month, assigns(:date)
  end

  test "should require admin access" do
    logout
    user = users(:vivian)
    login_as user

    get admin_analytics_path
    assert_response :redirect
  end
end

