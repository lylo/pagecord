require "test_helper"

class Admin::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @admin_user = users(:joel)
    login_as @admin_user
  end

  test "should get index" do
    get admin_blogs_url
    assert_response :success
  end

  test "should search users by email" do
    user1 = users(:vivian) # vivian@example.com
    user2 = users(:joel)   # joel@example.com

    get admin_blogs_path(search: "vivian")

    assert_response :success
    assert_includes @response.body, user1.email
    assert_not_includes @response.body, user2.email
  end

  test "should search users by subdomain" do
    user1 = users(:vivian)
    user2 = users(:joel)

    get admin_blogs_path(search: user1.blog.subdomain)

    assert_response :success
    assert_includes @response.body, user1.blog.subdomain
    assert_not_includes @response.body, user2.blog.subdomain
  end

  test "should handle empty search parameter" do
    get admin_blogs_path(search: "")

    assert_response :success
    # Should show all users when search is empty
    assert_includes @response.body, users(:vivian).email
    assert_includes @response.body, users(:joel).email
  end

  test "should return empty results for non-matching search" do
    get admin_blogs_path(search: "nonexistent@example.com")

    assert_response :success
    assert_not_includes @response.body, users(:vivian).email
    assert_not_includes @response.body, users(:joel).email
  end

  test "should get index without filters" do
    get admin_blogs_path
    assert_response :success
  end

  test "should filter by paid status" do
    get admin_blogs_path, params: { status: "paid" }
    assert_response :success

    # Should show only users with active paid subscriptions
    paid_count = Subscription.active_paid.count
    assert_select "div", text: /Showing paid subscribers \(#{paid_count} results?\)/
    assert_select "td", text: /elliot/ # lifetime user
    assert_select "a[href='#{admin_blogs_path}']", text: "Clear filters"
  end

  test "should filter by comped status" do
    # Make joel's subscription comped
    users(:joel).subscription.update!(plan: "complimentary")

    get admin_blogs_path, params: { status: "comped" }
    assert_response :success

    # Should show only comped users (joel now)
    assert_select "div", text: /Showing comped users \(1 result\)/
    assert_select "td", text: /joel/
  end

  test "should combine search and status filters" do
    get admin_blogs_path, params: { search: "joel", status: "paid" }
    assert_response :success

    assert_select "div", text: /found in paid subscribers for/
  end

  test "should preserve status filter when searching" do
    get admin_blogs_path, params: { status: "paid" }
    assert_response :success

    assert_select "input[type='hidden'][name='status'][value='paid']"
  end

  test "should show clickable stats summary links when no filter is active" do
    get admin_blogs_path
    assert_response :success

    assert_select "a[href='#{admin_blogs_path(status: 'paid')}']"
    assert_select "a[href='#{admin_blogs_path(status: 'comped')}']"
  end

  test "should highlight active filter in stats summary" do
    get admin_blogs_path, params: { status: "paid" }
    assert_response :success

    assert_select "a[href='#{admin_blogs_path}']", text: /users? in total/
  end

  test "should require admin access" do
    non_admin = users(:vivian)
    login_as non_admin

    get admin_blogs_path
    assert_redirected_to root_path
  end

  test "should show correct status labels in table" do
    get admin_blogs_path
    assert_response :success

    assert_select "td", text: "Premium"
    assert_select "td", text: "Free"
  end

  test "should handle empty search results with status filter" do
    get admin_blogs_path, params: { search: "nonexistent", status: "paid" }
    assert_response :success

    assert_select "div", text: /No paid subscribers found for/
  end
end
