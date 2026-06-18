require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  test "should get terms page" do
    get terms_path
    assert_response :success
  end

  test "should get privacy page" do
    get privacy_path
    assert_response :success
  end

  test "should get faq page" do
    get faq_path
    assert_response :success
  end

  test "should get pagecord vs hey world page" do
    get pagecord_vs_hey_world_path
    assert_response :success
  end

  test "should get comparison pages" do
    [
      pagecord_vs_about_me_path,
      pagecord_vs_medium_path,
      pagecord_vs_hey_world_path,
      pagecord_vs_wordpress_path,
      pagecord_vs_substack_path
    ].each do |path|
      get path
      assert_response :success
    end
  end

  test "should get blogging by email page" do
    get blogging_by_email_path
    assert_response :success
  end

  test "should get topic landing pages" do
    [
      personal_website_path,
      minimalist_blogging_path,
      blogging_by_email_path,
      blog_with_newsletter_path,
      blogger_alternative_path,
      indie_blogging_platform_path
    ].each do |path|
      get path
      assert_response :success
    end
  end

  test "should get robots.txt" do
    get robots_path
    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "Blog robots.txt for Pagecord"
    assert_includes @response.body, "sitemap.xml"
  end

  test "sitemap includes topic landing pages" do
    get public_sitemap_path(format: :xml)
    assert_response :success
    assert_includes @response.body, "https://pagecord.com/personal-website"
    assert_includes @response.body, "https://pagecord.com/minimalist-blogging"
    assert_includes @response.body, "https://pagecord.com/blog-with-newsletter"
    assert_includes @response.body, "https://pagecord.com/blogger-alternative"
    assert_includes @response.body, "https://pagecord.com/indie-blogging-platform"
  end
end
