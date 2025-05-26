require "test_helper"

class AppHelperTest < ActionView::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "persisted_value returns was value when available" do
    @blog.update(name: "joel.joel")

    assert_not @blog.valid?
    assert_equal "joel", persisted_value(@blog, :name)
    assert_equal "joel", persisted_value(@blog, "name")
  end

  test "persisted_value returns current value when no was value exists" do
    assert_equal "joel", persisted_value(@blog, :name)
  end
end
