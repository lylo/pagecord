require "test_helper"

class Blogs::RobotsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "should get robots.txt for regular domain" do
    get blog_robots_path

    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "Blog robots.txt for #{@blog.subdomain}"
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
    assert_includes @response.body, "Blog robots.txt for #{blog.subdomain}"
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

  test "should serve custom robots txt for subscriber" do
    custom_robots_txt = "User-agent: Bubbles\nAllow: /\n"
    @blog.update!(custom_robots_txt: custom_robots_txt)

    get blog_robots_path

    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_equal custom_robots_txt, @response.body
  end

  test "should serve custom robots txt for subscriber when search indexing is disabled" do
    custom_robots_txt = "User-agent: Bubbles\nAllow: /\n"
    @blog.update!(allow_search_indexing: false, custom_robots_txt: custom_robots_txt)

    get blog_robots_path

    assert_response :success
    assert_equal custom_robots_txt, @response.body
  end

  test "should ignore custom robots txt for non-subscriber" do
    blog = blogs(:vivian)
    blog.update!(custom_robots_txt: "User-agent: Bubbles\nAllow: /\n")
    host! "#{blog.subdomain}.#{Rails.application.config.x.domain}"

    get blog_robots_path

    assert_response :success
    assert_includes @response.body, "User-agent: GPTBot"
  end

  test "should ignore custom robots txt for lapsed subscriber" do
    @user = users(:joel)
    @user.subscription.update!(next_billed_at: 1.day.ago)
    @blog.update!(custom_robots_txt: "User-agent: Bubbles\nAllow: /\n")

    get blog_robots_path

    assert_response :success
    assert_includes @response.body, "User-agent: GPTBot"
  end
end
