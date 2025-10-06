require "test_helper"

class LiquidRenderingTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @blog = @user.blog
    @blog.update!(features: [ "home_page" ])
  end

  test "renders posts liquid tag" do
    @blog.posts.create!(title: "First Post", content: "Content 1", status: :published, published_at: 2.days.ago)
    @blog.posts.create!(title: "Second Post", content: "Content 2", status: :published, published_at: 1.day.ago)

    page = @blog.pages.create!(title: "Posts Page", content: "{% posts %}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /First Post/
    assert_select "body", text: /Second Post/
  end

  test "renders posts tag with limit parameter" do
    3.times do |i|
      @blog.posts.create!(title: "Post #{i}", content: "Content", status: :published, published_at: i.days.ago)
    end

    page = @blog.pages.create!(title: "Limited Posts", content: "{% posts limit: 2 %}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Post 0/
    assert_select "body", text: /Post 1/
    assert_select "body", text: /Post 2/, count: 0
  end

  test "renders posts tag with tag filter" do
    @blog.posts.create!(title: "Ruby Post", content: "Content", status: :published, tag_list: [ "ruby" ])
    @blog.posts.create!(title: "JS Post", content: "Content", status: :published, tag_list: [ "javascript" ])

    page = @blog.pages.create!(title: "Ruby Posts", content: "{% posts tag: 'ruby' %}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Ruby Post/
    assert_select "body", text: /JS Post/, count: 0
  end

  test "renders tag_list liquid tag" do
    @blog.posts.create!(title: "Post 1", content: "Content", status: :published, tag_list: [ "ruby", "rails" ])
    @blog.posts.create!(title: "Post 2", content: "Content", status: :published, tag_list: [ "javascript" ])

    page = @blog.pages.create!(title: "Tags", content: "{% tag_list %}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /ruby/
    assert_select "body", text: /rails/
    assert_select "body", text: /javascript/
  end

  test "tag_list only shows tags from visible posts" do
    @blog.posts.create!(title: "Published", content: "Content", status: :published, tag_list: [ "published" ])
    @blog.posts.create!(title: "Draft", content: "Content", status: :draft, tag_list: [ "draft" ])
    @blog.posts.create!(title: "Hidden", content: "Content", status: :published, hidden: true, tag_list: [ "hidden" ])

    page = @blog.pages.create!(title: "Tags", content: "{% tag_list %}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /published/
    assert_select "body", text: /draft/, count: 0
    assert_select "body", text: /hidden/, count: 0
  end

  test "handles liquid syntax errors gracefully" do
    page = @blog.pages.create!(title: "Bad Syntax", content: "{% posts", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /{% posts/
  end

  test "renders multiple liquid tags in same page" do
    @blog.posts.create!(title: "Ruby Post", content: "Content", status: :published, tag_list: [ "ruby" ])

    page = @blog.pages.create!(
      title: "Multi Tag Page",
      content: "{% posts limit: 1 %} and {% tag_list %}",
      status: :published
    )

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Ruby Post/
    assert_select "body", text: /ruby/
  end

  test "does not process liquid tags in regular posts" do
    post = @blog.posts.create!(
      title: "Regular Post",
      content: "This is a post with {% posts %} tag",
      status: :published
    )

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    # Liquid tag should appear literally, not be processed
    assert_includes response.body, "{% posts %}"
  end

  test "processes liquid tags only in pages not posts" do
    @blog.posts.create!(title: "Test Post", content: "Content", status: :published)

    # Create a regular post with liquid tag
    regular_post = @blog.posts.create!(
      title: "Regular Post",
      content: "{% posts %}",
      status: :published,
      is_page: false
    )

    # Create a page with liquid tag
    page = @blog.pages.create!(
      title: "Page",
      content: "{% posts %}",
      status: :published
    )

    # Regular post should show liquid tag literally in the content
    get blog_post_url(subdomain: @blog.subdomain, slug: regular_post.slug)
    assert_response :success
    assert_select ".lexxy-content", text: /{% posts %}/

    # Page should process the liquid tag in the content
    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)
    assert_response :success
    assert_select ".lexxy-content", text: /Test Post/
    # Make sure liquid tag is not in the actual content area
    doc = Nokogiri::HTML(response.body)
    content_div = doc.at_css(".lexxy-content")
    assert_not_includes content_div.text, "{% posts %}"
  end

  test "respects raw blocks to escape liquid processing" do
    @blog.posts.create!(title: "Test Post", content: "Content", status: :published)

    page = @blog.pages.create!(
      title: "Raw Example",
      content: "<p>Normal: {% posts %}</p><p>Escaped: {% raw %}{% posts %}{% endraw %}</p>",
      status: :published
    )

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    doc = Nokogiri::HTML(response.body)
    content_div = doc.at_css(".lexxy-content")

    # Normal liquid tag should be processed
    assert_includes content_div.text, "Test Post"

    # Raw block should NOT be processed - liquid tag appears literally
    assert_includes content_div.inner_html, "{% posts %}"
  end
end
