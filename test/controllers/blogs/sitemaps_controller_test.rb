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
end
