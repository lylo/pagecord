require "test_helper"

class LiquidRenderingTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @blog = @user.blog
    @blog.posts.destroy_all
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
end
