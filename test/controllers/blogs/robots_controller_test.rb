require "test_helper"

class Blogs::RobotsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)
    host! "#{@blog.name}.#{Rails.application.config.x.domain}"
  end

  test "should get robots.txt for regular domain" do
    get blog_robots_path

    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "Blog robots.txt for #{@blog.name}"
    assert_includes @response.body, "Allow: /"
    assert_includes @response.body, "Sitemap:"
    assert_includes @response.body, "User-agent: GPTBot"
    assert_includes @response.body, "Disallow: /"
  end

  test "should get robots.txt for custom domain" do
    blog = blogs(:annie)
    get "/robots.txt", headers: { "Host" => blog.custom_domain }

    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "Blog robots.txt for #{blog.name}"
    assert_includes @response.body, "Allow: /"
    assert_includes @response.body, "Sitemap:"
    assert_includes @response.body, "User-agent: GPTBot"
    assert_includes @response.body, "Disallow: /"
  end

  test "should disallow all indexing" do
    @blog.update!(allow_search_indexing: false)

    get blog_robots_path

    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_equal "User-agent: *\nDisallow: /\n", @response.body
  end
end
