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

  test "custom_theme? returns true when theme is custom" do
    @blog.theme = "custom"
    assert @blog.custom_theme?
  end

  test "custom_theme? returns false when theme is not custom" do
    @blog.theme = "mint"
    assert_not @blog.custom_theme?
  end

  test "should validate custom theme colors with valid hex codes" do
    @blog.theme = "custom"
    @blog.custom_theme_bg_light = "#abcdef"
    @blog.custom_theme_text_light = "#123"
    @blog.custom_theme_accent_light = "#AABBCC"
    @blog.custom_theme_bg_dark = "#000000"
    @blog.custom_theme_text_dark = "#FFF"
    @blog.custom_theme_accent_dark = "#112233"
    assert @blog.valid?
  end

  test "should not validate custom theme colors if theme is not custom" do
    @blog.theme = "mint"
    @blog.custom_theme_bg_light = "invalid-color"
    assert @blog.valid? # Should not add error because theme is not custom
  end

  test "should reject custom theme colors with invalid format" do
    @blog.theme = "custom"
    @blog.custom_theme_bg_light = "not-a-color"
    assert_not @blog.valid?
    assert_includes @blog.errors.messages[:custom_theme_bg_light], "must be a valid hex color code (e.g., #RRGGBB)"
  end

  test "custom_theme_colors returns correct structure with custom values" do
    @blog.theme = "custom"
    @blog.custom_theme_bg_light = "#111"
    @blog.custom_theme_text_light = "#222"
    @blog.custom_theme_accent_light = "#333"
    @blog.custom_theme_bg_dark = "#AAA"
    @blog.custom_theme_text_dark = "#BBB"
    @blog.custom_theme_accent_dark = "#CCC"

    colors = @blog.custom_theme_colors
    assert_equal "#111", colors[:light][:bg]
    assert_equal "#222", colors[:light][:text]
    assert_equal "#333", colors[:light][:accent]
    assert_equal "#AAA", colors[:dark][:bg]
    assert_equal "#BBB", colors[:dark][:text]
    assert_equal "#CCC", colors[:dark][:accent]
  end

  test "custom_theme_colors returns default values when custom colors are nil" do
    @blog.theme = "custom"
    @blog.custom_theme_bg_light = nil
    @blog.custom_theme_text_light = nil
    @blog.custom_theme_accent_light = nil
    @blog.custom_theme_bg_dark = nil
    @blog.custom_theme_text_dark = nil
    @blog.custom_theme_accent_dark = nil

    colors = @blog.custom_theme_colors
    assert_equal "#ffffff", colors[:light][:bg]
    assert_equal "#334155", colors[:light][:text]
    assert_equal "#334155", colors[:light][:accent]
    assert_equal "#0f172a", colors[:dark][:bg]
    assert_equal "#cbd5e1", colors[:dark][:text]
    assert_equal "#ffffff", colors[:dark][:accent]
  end
end
