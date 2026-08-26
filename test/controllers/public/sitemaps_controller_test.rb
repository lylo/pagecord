require "test_helper"

class Public::SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "sitemap includes topic landing pages" do
    get public_sitemap_path(format: :xml)

    assert_response :success
    assert_includes @response.body, "https://pagecord.com/personal-website"
    assert_includes @response.body, "https://pagecord.com/minimalist-blogging"
    assert_includes @response.body, "https://pagecord.com/blogger-alternative"
    assert_includes @response.body, "https://pagecord.com/indie-blogging-platform"
  end
end
