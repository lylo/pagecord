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
    assert_equal @blog.all_posts.visible.count + 1, Nokogiri::XML(@response.body).xpath("//xmlns:url").count
  end

  test "sitemap includes pages" do
    get blog_sitemap_path(subdomain: @blog.subdomain)

    assert_response :success
    locs = Nokogiri::XML(@response.body).xpath("//xmlns:url/xmlns:loc").map(&:text)
    @blog.pages.visible.each do |page|
      assert_includes locs, post_url(page)
    end
    assert @blog.pages.visible.any?, "fixture sanity: expected blog to have visible pages"
  end

  test "should get sitemap for custom domain" do
    blog = blogs(:annie)
    get "/sitemap.xml", headers: { "Host" => blog.custom_domain }

    assert_response :success
    assert_equal blog.all_posts.count, Nokogiri::XML(@response.body).xpath("//xmlns:url").count
  end

  test "sitemap lists the home page only at the blog root" do
    blog = blogs(:annie)
    get "/sitemap.xml", headers: { "Host" => blog.custom_domain }

    locs = Nokogiri::XML(@response.body).xpath("//xmlns:url/xmlns:loc").map(&:text)
    assert_includes locs, blog_home_url(blog)
    assert_not_includes locs, post_url(blog.home_page)
  end

  test "should return 406 for unsupported format" do
    get blog_sitemap_path(subdomain: @blog.subdomain, format: :gzip)

    assert_response :not_acceptable
    assert_equal "", @response.body # Ensure no body is returned for unsupported formats
  end
end
