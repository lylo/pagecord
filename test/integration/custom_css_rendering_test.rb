require "test_helper"

class CustomCssRenderingTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @blog = @user.blog
  end

  test "renders custom css in head when feature is enabled and css is present" do
    @blog.update(features: [ "custom_css" ], custom_css: ".blog { background: red; }")
    post = posts(:one)

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select "head style", text: /\.blog { background: red; }/
  end

  test "does not render custom css when feature is disabled" do
    @blog.update(features: [], custom_css: ".blog { background: red; }")
    post = posts(:one)

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select "head style", text: /\.blog { background: red; }/, count: 0
  end

  test "does not render style tag when custom_css is blank" do
    @blog.update(features: [ "custom_css" ], custom_css: nil)
    post = posts(:one)

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    # Check that there's no style tag containing custom CSS
    # (there may be other style tags, but not one with custom CSS marker)
    doc = Nokogiri::HTML(response.body)
    style_tags = doc.css("head style")
    custom_css_styles = style_tags.select { |tag| tag.text.strip.empty? }
    assert_equal 0, custom_css_styles.length
  end

  test "renders custom css on blog pages" do
    @blog.update(features: [ "custom_css" ], custom_css: ".custom-style { color: blue; }")
    post = posts(:one)
    page = posts(:about)

    # Test on individual post
    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)
    assert_response :success
    assert_select "head style", text: /\.custom-style { color: blue; }/

    # Test on page
    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)
    assert_response :success
    assert_select "head style", text: /\.custom-style { color: blue; }/
  end
end
