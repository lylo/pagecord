require "test_helper"

class Blog::CustomCodeTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "head code accepts the elements that belong in a head" do
    Blog::CustomCode::HEAD_ELEMENTS.each do |tag|
      @blog.custom_head_html = "<#{tag}></#{tag}>"
      assert @blog.valid?, "expected <#{tag}> to be allowed: #{@blog.errors[:custom_head_html].inspect}"
    end
  end

  test "head code accepts a real analytics snippet" do
    @blog.custom_head_html = %(<script defer data-domain="joel.pagecord.com" src="https://plausible.io/js/script.js"></script>)

    assert @blog.valid?
  end

  test "head code accepts comments and blank lines" do
    @blog.custom_head_html = %(<!-- analytics -->\n\n<meta name="verify" content="abc">\n)

    assert @blog.valid?
  end

  test "head code rejects other elements and names the offender" do
    @blog.custom_head_html = %(<script src="/a.js"></script>\n<div id="widget"></div>)

    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_head_html].first, "<div>"
    assert_includes @blog.errors[:custom_head_html].first, "body code"
  end

  test "head code explains why title and base are not allowed" do
    @blog.custom_head_html = "<title>My Blog</title>"
    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_head_html].first, "Blog Settings"
    assert_not_includes @blog.errors[:custom_head_html].first, "body code"

    @blog.custom_head_html = %(<base href="/">)
    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_head_html].first, "every link on your blog"
  end

  test "custom code is enabled by default" do
    assert_predicate Blog.new, :custom_code_enabled?
  end

  test "head code rejects bare text" do
    @blog.custom_head_html = %(paste this: <meta name="verify" content="abc">)

    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_head_html].first, "the text outside those tags"
  end

  test "head code rejects an unclosed script tag" do
    @blog.custom_head_html = %(<script src="https://plausible.io/js/script.js">)

    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_head_html], "has an unclosed <script> tag"
  end

  test "body code accepts arbitrary markup" do
    @blog.custom_body_html = %(<div id="chat-widget"></div>\n<noscript><iframe src="https://example.com/gtm"></iframe></noscript>)

    assert @blog.valid?
  end

  test "both fields reject content over the size limit by bytes" do
    oversized = "é" * (Blog::CustomCode::MAX_SIZE / 2)
    assert_equal Blog::CustomCode::MAX_SIZE, oversized.bytesize
    assert_operator oversized.length, :<, Blog::CustomCode::MAX_SIZE

    @blog.custom_body_html = oversized
    assert @blog.valid?, "expected exactly MAX_SIZE bytes to be allowed"

    @blog.custom_body_html = oversized + "!"
    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_body_html].first, "too large"
  end

  test "normalises line endings and blanks out whitespace-only values" do
    @blog.update!(custom_head_html: "<meta name=\"a\" content=\"b\">\r\n<meta name=\"c\" content=\"d\">\r\n", custom_body_html: "   \n  ")

    assert_equal %(<meta name="a" content="b">\n<meta name="c" content="d">), @blog.custom_head_html
    assert_nil @blog.custom_body_html
  end

  test "renders for a subscribed owner" do
    @blog.update!(custom_head_html: "<meta name=\"a\" content=\"b\">", custom_body_html: "<div></div>")

    assert @blog.user.subscribed?
    assert_equal "<meta name=\"a\" content=\"b\">", @blog.custom_head_html_for_render
    assert_equal "<div></div>", @blog.custom_body_html_for_render
    assert_predicate @blog.custom_head_html_for_render, :html_safe?
  end

  test "does not render when disabled, but keeps the content" do
    @blog.update!(custom_head_html: "<meta name=\"a\" content=\"b\">", custom_body_html: "<div></div>", custom_code_enabled: false)

    assert_nil @blog.custom_head_html_for_render
    assert_nil @blog.custom_body_html_for_render
    assert_equal "<meta name=\"a\" content=\"b\">", @blog.reload.custom_head_html
  end

  test "does not render when the subscription has lapsed, but keeps the content" do
    @blog.update!(custom_head_html: "<meta name=\"a\" content=\"b\">", custom_body_html: "<div></div>")
    @blog.user.subscription.destroy!

    assert_nil @blog.reload.custom_head_html_for_render
    assert_nil @blog.custom_body_html_for_render
    assert_equal "<meta name=\"a\" content=\"b\">", @blog.custom_head_html
  end
end
