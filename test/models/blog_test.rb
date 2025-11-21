require "test_helper"

class BlogTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
  end

  test "should validate length of subdomain" do
    @blog.subdomain = "a" * 21
    assert_not @blog.valid?

    @blog.subdomain = "a"
    assert_not @blog.valid?

    @blog.subdomain = "aaaa"
    assert @blog.valid?
  end

  test "should validate presence of subdomain" do
    @blog.subdomain = ""
    assert_not @blog.valid?
  end

  test "should validate uniqueness of subdomain" do
    @blog.subdomain = "vivian"
    assert_not @blog.valid?
  end

  test "should reserve subdomain" do
    @blog.subdomain = "pagecord"
    assert_not @blog.valid?
  end

  test "should validate format of subdomain" do
    @blog.subdomain = "abcdef-"
    assert_not @blog.valid?

    @blog.subdomain = "%12312"
    assert_not @blog.valid?

    @blog.subdomain = "abcdef_1234"
    assert_not @blog.valid?

    @blog.subdomain = "abcdef1234"
    assert @blog.valid?
  end

  test "should validate length of bio" do
    @blog.bio = "a" * 513
    assert_not @blog.valid?
  end

  test "should store subdomain in lowercase" do
    @blog.subdomain = "JOEL"
    @blog.save
    assert_equal "joel", @blog.subdomain
  end

  test "should generate unique delivery email" do
    user = User.create!(email: "newuser@newuser.com", blog: Blog.new(subdomain: "newuser"))
    assert user.blog.delivery_email.present?
    assert user.blog.delivery_email =~ /newuser_[a-zA-Z0-9]{8}@post.pagecord.com/
  end

  test "should allow valid custom domain" do
    @blog.custom_domain = "newdomain.com"

    assert @blog.valid?
  end

  test "should not allow invalid custom domain format" do
    @blog.custom_domain = "blah blah"

    assert_not @blog.valid?
  end

  test "should validate restricted custom domain" do
    @blog.custom_domain = "pagecord.com"

    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Custom domain is restricted"
  end

  test "should record custom domain change" do
    @blog.update!(custom_domain: "newdomain.com")

    assert @blog.valid?
    assert_equal 1, @blog.custom_domain_changes.count
  end

  test "should normalize custom domain" do
    @blog.custom_domain = ""
    @blog.save!

    assert_nil @blog.reload.custom_domain
  end

  test "should destroy post digests on destroy" do
    assert_difference "PostDigest.count", -1 do
      @blog.destroy
    end
  end

  test "should validate google site verification" do
    @blog.google_site_verification = "GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44"
    assert @blog.valid?

    @blog.google_site_verification = "abc123_DEF-456"
    assert @blog.valid?

    @blog.google_site_verification = "simple123"
    assert @blog.valid?

    @blog.google_site_verification = ""
    assert @blog.valid?

    @blog.google_site_verification = nil
    assert @blog.valid?

    @blog.google_site_verification = "invalid code with spaces"
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Google site verification can only contain letters, numbers, underscores, and hyphens"
  end

  test "should validate locale" do
    @blog.locale = "en"
    assert @blog.valid?

    @blog.locale = "es"
    assert @blog.valid?

    @blog.locale = "fr"
    assert @blog.valid?

    @blog.locale = "de"
    assert @blog.valid?

    @blog.locale = "invalid"
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Locale invalid is not a supported locale"

    @blog.locale = nil
    assert_not @blog.valid?
  end

  test "should have default locale" do
    new_blog = Blog.new(subdomain: "test", user: users(:joel))
    assert_equal "en", new_blog.locale
  end

  test "should sanitize valid custom CSS" do
    @blog.custom_css = ".blog { color: red; }"
    assert @blog.valid?
    assert_equal ".blog { color: red; }", @blog.custom_css
  end

  test "should reject custom CSS with XSS attempt via </style>" do
    @blog.custom_css = ".blog { color: red; }</style><script>alert(1)</script>"
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Custom css contains invalid or potentially unsafe content"
  end

  test "should reject custom CSS with script tags" do
    @blog.custom_css = ".blog { color: red; }<script>alert(1)</script>"
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Custom css contains invalid or potentially unsafe content"
  end

  test "should reject invalid @import URLs" do
    @blog.custom_css = '@import url("https://evil.com/steal.css");'
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Custom css contains invalid or potentially unsafe content"
  end

  test "should allow Google Fonts @import" do
    @blog.custom_css = '@import url("https://fonts.googleapis.com/css2?family=Roboto");'
    assert @blog.valid?
    assert_includes @blog.custom_css, "fonts.googleapis.com"
  end

  test "should allow CSS custom properties" do
    @blog.custom_css = "[data-theme] { --theme-bg: #f4f5dc; --theme-accent: #3a2fad; }"
    assert @blog.valid?
    assert_includes @blog.custom_css, "--theme-bg"
    assert_includes @blog.custom_css, "--theme-accent"
  end

  test "should allow CSS logical properties" do
    @blog.custom_css = "header hr { margin-inline: auto; padding-inline-start: 1rem; }"
    assert @blog.valid?
    assert_includes @blog.custom_css, "margin-inline"
    assert_includes @blog.custom_css, "padding-inline-start"
  end

  test "should allow CSS with leading and trailing whitespace" do
    @blog.custom_css = "\n\n.blog { color: red; }\n\n"
    assert @blog.valid?
    assert_includes @blog.custom_css, "color: red"
  end

  test "should reject CSS exceeding size limit" do
    @blog.custom_css = "." + ("a" * 11_000) # Exceeds 10KB limit
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Custom css contains invalid or potentially unsafe content"
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
