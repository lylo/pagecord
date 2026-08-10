require "test_helper"

class Admin::ChurnsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should get index" do
    login_as users(:joel)

    get admin_churns_path

    assert_response :success
    assert_select "td", text: /joel/
    assert_select "td", text: /gone/
  end

  test "groups every churn into a month" do
    login_as users(:joel)

    get admin_churns_path

    assert_equal Churn.count, assigns(:by_month).values.sum(&:size)
  end

  test "should not be accessible to non-admins" do
    login_as users(:vivian)

    get admin_churns_path

    assert_redirected_to root_path
  end
end
