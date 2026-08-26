require "test_helper"

class Public::RobotsControllerTest < ActionDispatch::IntegrationTest
  test "should get robots.txt" do
    get robots_path

    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "Marketing site robots.txt for Pagecord"
    assert_includes @response.body, "sitemap.xml"
    refute_includes @response.body, "Disallow"
  end
end
