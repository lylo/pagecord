require "test_helper"

class AppHelperTest < ActionView::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "persisted_value returns was value when available" do
    @blog.update(subdomain: "joel.joel")

    assert_not @blog.valid?
    assert_equal "joel", persisted_value(@blog, :subdomain)
    assert_equal "joel", persisted_value(@blog, "subdomain")
  end

  test "persisted_value returns current value when no was value exists" do
    assert_equal "joel", persisted_value(@blog, :subdomain)
  end

  test "a nested route matching two section names highlights only its controller" do
    stubs(:controller_name).returns("comments")
    request.path = "/app/posts/abc123/comments"

    assert is_current_path?("comments")
    assert_not is_current_path?("posts")
  end

  test "a section whose controller isn't a section still matches on path" do
    stubs(:controller_name).returns("audience")
    request.path = "/app/settings/audience"

    assert is_current_path?("settings")
  end
end
