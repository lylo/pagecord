require "test_helper"

class ThemeableTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "default theme values" do
    new_blog = Blog.new
    assert_equal "base", new_blog.theme
    assert_equal "sans", new_blog.font
    assert_equal "standard", new_blog.width
  end

  test "theme validation" do
    @blog.theme = "invalid_theme"
    assert_not @blog.valid?
    assert_includes @blog.errors[:theme], "invalid_theme is not a valid theme"

    @blog.theme = "mint"
    @blog.valid?
  end

  test "font validation" do
    @blog.font = "comic-sans"
    assert_not @blog.valid?
    assert_includes @blog.errors[:font], "comic-sans is not a valid font"

    @blog.font = "serif"
    @blog.valid?
  end

  test "width validation" do
    @blog.width = "extra-wide"
    assert_not @blog.valid?
    assert_includes @blog.errors[:width], "extra-wide is not a valid width"

    @blog.width = "wide"
    @blog.valid?
  end

  test "font helper methods" do
    @blog.font = "serif"
    assert @blog.serif?
    assert_not @blog.sans_serif?

    @blog.font = "sans-serif"
    assert @blog.sans_serif?
    assert_not @blog.serif?
  end

  test "width helper methods" do
    @blog.width = "narrow"
    assert @blog.narrow?
    assert_not @blog.standard?
    assert_not @blog.wide?

    @blog.width = "standard"
    assert @blog.standard?
    assert_not @blog.narrow?
    assert_not @blog.wide?

    @blog.width = "wide"
    assert @blog.wide?
    assert_not @blog.narrow?
    assert_not @blog.standard?
  end
end
