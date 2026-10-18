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

  test "preserves gap properties" do
    css = "nav { gap: 1rem; row-gap: 0.25rem; column-gap: 0.75rem; }"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "gap: 1rem"
    assert_includes result, "row-gap: 0.25rem"
    assert_includes result, "column-gap: 0.75rem"
  end

  test "preserves modern layout properties" do
    css = ".a { display: grid; place-items: center; inset: 0; scrollbar-width: thin; scrollbar-color: red blue; scroll-margin-top: 2rem; }"
    assert_empty Css::Sanitizer.problems(css)
    assert_equal css, Css::Sanitizer.sanitize_stylesheet(css)
  end

  test "preserves initial-letter for drop caps" do
    css = "p::first-letter { initial-letter: 3; -webkit-initial-letter: 3; }"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "initial-letter: 3"
    assert_includes result, "-webkit-initial-letter: 3"
  end

  test "preserves @supports feature queries" do
    css = "@supports (initial-letter: 2) { p::first-letter { color: red; } }"
    result = Css::Sanitizer.sanitize_stylesheet(css)
    assert_includes result, "@supports"
    assert_includes result, "initial-letter: 2"
    assert_includes result, "color: red"
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

  test "problems names a disallowed property and its line" do
    css = "body { color: red; }\n.a { colour: blue; }"
    assert_equal [ "Line 2: the colour property isn't supported." ], Css::Sanitizer.problems(css)
  end

  test "problems names a disallowed value" do
    css = "body { background: url(javascript:alert(1)); }"
    assert_match "Line 1: this value for background isn't allowed", Css::Sanitizer.problems(css).sole
  end

  test "problems names a disallowed at-rule" do
    css = "a { color: red; }\n@font-feature-values Foo { @swash { fancy: 1; } }"
    assert_equal [ "Line 2: @font-feature-values isn't supported." ], Css::Sanitizer.problems(css)
  end

  test "problems finds properties inside media queries" do
    css = "@media (min-width: 40em) {\n  .a { zoom-level: 2; }\n}"
    assert_equal [ "Line 2: the zoom-level property isn't supported." ], Css::Sanitizer.problems(css)
  end

  test "problems explains nested rules" do
    assert_match "Line 3: nested rules aren't supported. Move what's inside .post into its own rule",
      Css::Sanitizer.problems("p { color: red; }\n.post {\n  & h1 { color: blue; }\n}").sole
  end

  test "problems reports a stray semicolon" do
    assert_equal [ "Line 1 has a stray semicolon." ], Css::Sanitizer.problems("a { color: red;; }")
  end

  test "problems is empty for CSS the sanitizer keeps" do
    css = "@import url(\"https://fonts.bunny.net/css?family=inter\");\n@media (prefers-color-scheme: dark) { :root { --x: 1px; } a { color: red; } }"
    assert_empty Css::Sanitizer.problems(css)
  end
end
