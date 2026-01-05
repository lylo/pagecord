require "test_helper"

class Css::SanitizerTest < ActiveSupport::TestCase
  test "returns empty string for blank input" do
    assert_equal "", Css::Sanitizer.sanitize_stylesheet(nil)
    assert_equal "", Css::Sanitizer.sanitize_stylesheet("")
  end

  test "returns empty string for oversized input" do
    huge_css = "a" * 3000
    assert_equal "", Css::Sanitizer.sanitize_stylesheet(huge_css)
  end

  test "preserves valid CSS" do
    css = "body { color: red; }"
    assert_includes Css::Sanitizer.sanitize_stylesheet(css), "color"
  end

  test "preserves CSS custom properties" do
    css = ":root { --theme-bg: #fff; }"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "--theme-bg"
  end

  test "preserves CSS logical properties" do
    css = "p { margin-inline-start: 1rem; padding-block: 2rem; }"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "margin-inline-start"
    assert_includes result, "padding-block"
  end

  test "allows Google Fonts @import" do
    css = '@import url("https://fonts.googleapis.com/css2?family=Roboto");'
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "fonts.googleapis.com"
  end

  test "allows Google Fonts static @import" do
    css = '@import url("https://fonts.gstatic.com/s/roboto/v30/font.woff2");'
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "fonts.gstatic.com"
  end

  test "allows Bunny Fonts @import" do
    css = '@import url("https://fonts.bunny.net/css?family=adamina:400");'
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "fonts.bunny.net"
  end

  test "strips disallowed @import URLs" do
    css = '@import url("https://evil.com/steal.css");'
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_not_includes result, "evil.com"
  end

  test "strips http @import URLs" do
    css = '@import url("http://fonts.googleapis.com/css2?family=Roboto");'
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_not_includes result, "fonts.googleapis.com"
  end

  test "handles invalid URLs gracefully" do
    css = '@import url("not a valid url at all");'
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_not_includes result, "not a valid url"
  end

  test "escapes style tag breakout attempts" do
    css = "body { content: '</style><script>alert(1)</script>'; }"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_not_includes result, "</style>"
  end

  test "normalizes line endings" do
    css = "body {\r\n  color: red;\r\n}"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_not_includes result, "\r"
  end
end
