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
