require "test_helper"

class Home::TrendingControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    host! Rails.application.config.x.domain
    @admin = users(:joel)
    login_as @admin
  end

  test "should show trending page" do
    get trending_path

    assert_response :success
    assert_select "h1", "Trending"
  end

  test "should show recent tab" do
    get trending_path(tab: "recent")

    assert_response :success
    assert_select "h1", "Trending"
  end

  test "defaults to trending tab" do
    get trending_path

    assert_response :success
    assert_select "nav a.bg-slate-900", "Trending"
  end

  test "excludes blogs with search indexing disabled from recent" do
    blog = blogs(:joel)
    blog.update!(allow_search_indexing: false)

    get trending_path(tab: "recent")

    assert_response :success
    assert_no_match blog.subdomain, response.body
  end

  test "excludes posts from discarded users from recent" do
    user = users(:elliot)
    user.discard!

    get trending_path(tab: "recent")

    assert_response :success
    assert_no_match user.blog.subdomain, response.body
  end

  test "redirects non-admin users" do
    non_admin = users(:joel)
    non_admin.update!(admin: false)

    get trending_path

    assert_redirected_to root_path
  end

  test "redirects logged-out users" do
    reset!
    host! Rails.application.config.x.domain

    get trending_path

    assert_redirected_to root_path
  end
end
