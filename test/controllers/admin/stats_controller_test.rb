require "test_helper"

class Admin::StatsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @admin_user = users(:joel)
    login_as @admin_user
  end

  test "should get index" do
    get admin_stats_url
    assert_response :success
  end

  test "should search users by email" do
    user1 = users(:vivian) # vivian@example.com
    user2 = users(:joel)   # joel@example.com

    get admin_stats_path(search: "vivian")

    assert_response :success
    assert_includes @response.body, user1.email
    assert_not_includes @response.body, user2.email
  end

  test "should search users by subdomain" do
    user1 = users(:vivian)
    user2 = users(:joel)

    get admin_stats_path(search: user1.blog.subdomain)

    assert_response :success
    assert_includes @response.body, user1.blog.subdomain
    assert_not_includes @response.body, user2.blog.subdomain
  end

  test "should handle empty search parameter" do
    get admin_stats_path(search: "")

    assert_response :success
    # Should show all users when search is empty
    assert_includes @response.body, users(:vivian).email
    assert_includes @response.body, users(:joel).email
  end

  test "should return empty results for non-matching search" do
    get admin_stats_path(search: "nonexistent@example.com")

    assert_response :success
    assert_not_includes @response.body, users(:vivian).email
    assert_not_includes @response.body, users(:joel).email
  end
end
