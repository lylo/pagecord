require "test_helper"

class Blogs::SitemapsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "should get sitemap" do
    get blog_sitemap_path(subdomain: @blog.subdomain)

    assert_response :success
    assert_equal @blog.posts.count + 1, Nokogiri::XML(@response.body).xpath("//xmlns:url").count
  end

  test "should get sitemap for custom domain" do
    blog = blogs(:annie)
    get "/sitemap.xml", headers: { "Host" => blog.custom_domain }

    assert_response :success
    assert_equal blog.posts.count + 1, Nokogiri::XML(@response.body).xpath("//xmlns:url").count
  end

  test "should return 406 for unsupported format" do
    get blog_sitemap_path(subdomain: @blog.subdomain, format: :gzip)

    assert_response :not_acceptable
    assert_equal "", @response.body # Ensure no body is returned for unsupported formats
  end
end
