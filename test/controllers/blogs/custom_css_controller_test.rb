require "test_helper"

class Blogs::CustomCssControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
    @blog.update!(custom_css: ".blog { color: rebeccapurple; }")
  end

  test "should serve the custom CSS as a stylesheet cached for a year" do
    get blog_custom_css_path(format: :css, v: @blog.custom_css_digest)

    assert_response :success
    assert_equal "text/css; charset=utf-8", response.content_type
    assert_equal ".blog { color: rebeccapurple; }", response.body
    assert_equal "max-age=#{1.year.to_i}, public, immutable", response.headers["Cache-Control"]
    assert_nil response.headers["Set-Cookie"]
  end

  test "should not cache a version that is not the current CSS" do
    get blog_custom_css_path(format: :css, v: "stale")

    assert_response :success
    assert_equal ".blog { color: rebeccapurple; }", response.body
    assert_equal "max-age=0, private, must-revalidate", response.headers["Cache-Control"]
  end

  test "should not find a stylesheet when there is no custom CSS" do
    @blog.update!(custom_css: nil)

    get blog_custom_css_path(format: :css)

    assert_response :not_found
  end

  test "should serve the stylesheet of a password protected blog to its login page" do
    @blog.update!(password: "open sesame")

    get blog_custom_css_path(format: :css)

    assert_response :success
  end

  test "should leave /custom to the post with that slug" do
    assert_recognizes({ controller: "blogs/posts", action: "show", slug: "custom" }, "http://#{host}/custom")
  end
end
