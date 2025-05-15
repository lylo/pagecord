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

  test "should get blogging by email page" do
    get blogging_by_email_path
    assert_response :success
  end

  test "should get robots.txt" do
    get robots_path
    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "Blog robots.txt for Pagecord"
    assert_includes @response.body, "sitemap.xml"
  end
end
