require "test_helper"

class Blogs::ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)

    host_subdomain! @blog.subdomain
  end

  test "blog pages enforce the permissive policy" do
    get blog_posts_path

    assert_response :success

    policy = response.headers["Content-Security-Policy"]
    assert_not_nil policy
    assert_nil response.headers["Content-Security-Policy-Report-Only"]

    assert_includes policy, "frame-src 'self' https:"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "base-uri 'self'"
  end

  test "app pages keep the report-only policy" do
    host! Rails.application.config.x.domain

    get "/login"

    assert_response :success
    assert_not_nil response.headers["Content-Security-Policy-Report-Only"]
    assert_nil response.headers["Content-Security-Policy"]
  end
end

class App::PreviewContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @blog = blogs(:joel)

    login_as @blog.user
  end

  test "post preview enforces the permissive policy" do
    get app_post_path(@blog.posts.first)

    assert_response :success
    assert_includes response.headers["Content-Security-Policy"], "frame-src 'self' https:"
    assert_nil response.headers["Content-Security-Policy-Report-Only"]
  end

  test "theme garden preview enforces the permissive policy" do
    get preview_app_settings_theme_garden_path(theme_templates(:minimal_mono))

    assert_response :success
    assert_includes response.headers["Content-Security-Policy"], "frame-src 'self' https:"
    assert_nil response.headers["Content-Security-Policy-Report-Only"]
  end
end
