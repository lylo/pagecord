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
end
