require "test_helper"

class Blogs::SitemapsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  test "should get sitemap" do
    blog = blogs(:joel)
    get blog_sitemap_path(name: blog.name)

    assert_response :success
    assert_equal blog.posts.count + 1, Nokogiri::XML(@response.body).xpath("//xmlns:url").count
  end

  test "should get sitemap for custom domain" do
    blog = blogs(:annie)
    get "/sitemap.xml", headers: { "Host" => blog.custom_domain }

    assert_response :success
    assert_equal blog.posts.count + 1, Nokogiri::XML(@response.body).xpath("//xmlns:url").count
  end

  test "should return 406 for unsupported format" do
    blog = blogs(:joel)
    get blog_sitemap_path(name: blog.name, format: :gzip)

    assert_response :not_acceptable
    assert_equal "", @response.body # Ensure no body is returned for unsupported formats
  end
end
