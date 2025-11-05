require "test_helper"

class CustomTagsRenderingTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @blog = @user.blog
  end

  test "renders posts custom tag" do
    @blog.posts.create!(title: "First Post", content: "Content 1", status: :published, published_at: 2.days.ago)
    @blog.posts.create!(title: "Second Post", content: "Content 2", status: :published, published_at: 1.day.ago)

    page = @blog.pages.create!(title: "Posts Page", content: "{{ posts }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /First Post/
    assert_select "body", text: /Second Post/
  end

  test "posts tag only shows visible posts" do
    @blog.posts.create!(title: "Published Post", content: "Content", status: :published, published_at: 2.days.ago)
    @blog.posts.create!(title: "Hidden Post", content: "Content", status: :published, hidden: true, published_at: 1.day.ago)
    @blog.posts.create!(title: "Draft Post", content: "Content", status: :draft, published_at: Time.current)

    page = @blog.pages.create!(title: "Posts Page", content: "{{ posts }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Published Post/
    assert_select "body", text: /Hidden Post/, count: 0
    assert_select "body", text: /Draft Post/, count: 0
  end

  test "renders posts tag with limit parameter" do
    3.times do |i|
      @blog.posts.create!(title: "Post #{i}", content: "Content", status: :published, published_at: i.days.ago)
    end

    page = @blog.pages.create!(title: "Limited Posts", content: "{{ posts | limit: 2 }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Post 0/
    assert_select "body", text: /Post 1/
    assert_select "body", text: /Post 2/, count: 0
  end

  test "renders posts tag with tag filter" do
    page = @blog.pages.create!(title: "Photography Posts", content: "{{ posts | tag: photography }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /The Beauty of Landscape Photography/
    assert_select "body", text: /Created with Trix/, count: 0
  end

  test "renders tags custom tag" do
    page = @blog.pages.create!(title: "Tags", content: "{{ tags }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /photography/
    assert_select "body", text: /technology/
    assert_select "ul.tag-list"
  end

  test "renders tags with inline style" do
    page = @blog.pages.create!(title: "Tags Inline", content: "{{ tags | style: inline }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "span.tags-inline"
    assert_select "body", text: /photography/
    assert_select "body", text: /technology/
    # Should not render as a list when inline
    assert_select "ul.tag-list", count: 0
  end

  test "tag_list only shows tags from visible posts" do
    @blog.posts.create!(title: "Published", content: "Content", status: :published, tag_list: [ "published" ])
    @blog.posts.create!(title: "Draft", content: "Content", status: :draft, tag_list: [ "draft" ])
    @blog.posts.create!(title: "Hidden", content: "Content", status: :published, hidden: true, tag_list: [ "hidden" ])

    page = @blog.pages.create!(title: "Tags", content: "{{ tags }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /published/
    assert_select "body", text: /draft/, count: 0
    assert_select "body", text: /hidden/, count: 0
  end

  test "handles malformed tags gracefully" do
    page = @blog.pages.create!(title: "Bad Syntax", content: "{{ posts", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /{{ posts/
  end

  test "renders multiple custom tags in same page" do
    page = @blog.pages.create!(
      title: "Multi Tag Page",
      content: "{{ posts | limit: 1 }} and {{ tags }}",
      status: :published
    )

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /photography/
  end

  test "does not process custom tags in regular posts" do
    post = @blog.posts.create!(
      title: "Regular Post",
      content: "This is a post with {{ posts }} tag",
      status: :published
    )

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    # Custom tag should appear literally, not be processed
    assert_includes response.body, "{{ posts }}"
  end

  test "processes custom tags only in pages not posts" do
    @blog.posts.create!(title: "Test Post", content: "Content", status: :published)

    # Create a regular post with custom tag
    regular_post = @blog.posts.create!(
      title: "Regular Post",
      content: "{{ posts }}",
      status: :published,
      is_page: false
    )

    # Create a page with custom tag
    page = @blog.pages.create!(
      title: "Page",
      content: "{{ posts }}",
      status: :published
    )

    # Regular post should show custom tag literally in the content
    get blog_post_url(subdomain: @blog.subdomain, slug: regular_post.slug)
    assert_response :success
    assert_select ".lexxy-content", text: /{{ posts }}/

    # Page should process the custom tag in the content
    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)
    assert_response :success
    assert_select ".lexxy-content", text: /Test Post/
    # Make sure custom tag is not in the actual content area
    doc = Nokogiri::HTML(response.body)
    content_div = doc.at_css(".lexxy-content")
    assert_not_includes content_div.text, "{{ posts }}"
  end

  test "renders posts tag with year filter" do
    @blog.posts.create!(title: "2024 Post", content: "Content", status: :published, published_at: Date.new(2024, 6, 15))
    @blog.posts.create!(title: "2025 Post", content: "Content", status: :published, published_at: Date.new(2025, 3, 20))

    page = @blog.pages.create!(title: "2025 Posts", content: "{{ posts | year: 2025 }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /2025 Post/
    assert_select "body", text: /2024 Post/, count: 0
  end

  test "renders posts tag with combined limit and tag parameters" do
    page = @blog.pages.create!(title: "Limited Photography", content: "{{ posts | limit: 1 | tag: photography }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    # Should show only 1 photography post (the most recent)
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /The Beauty of Landscape Photography/, count: 0
  end

  test "renders posts_by_year tag" do
    @blog.posts.create!(title: "2023 Post", content: "Content", status: :published, published_at: Date.new(2023, 6, 15))
    @blog.posts.create!(title: "2024 Post A", content: "Content", status: :published, published_at: Date.new(2024, 3, 20))
    @blog.posts.create!(title: "2024 Post B", content: "Content", status: :published, published_at: Date.new(2024, 8, 10))

    page = @blog.pages.create!(title: "Archive", content: "{{ posts_by_year }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    # Should show all posts grouped by year
    assert_select "body", text: /2023/
    assert_select "body", text: /2024/
    assert_select "body", text: /2023 Post/
    assert_select "body", text: /2024 Post A/
    assert_select "body", text: /2024 Post B/
  end

  test "renders posts_by_year tag with tag filter" do
    page = @blog.pages.create!(title: "Photography Archive", content: "{{ posts_by_year | tag: photography }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /The Beauty of Landscape Photography/
    assert_select "body", text: /Created with Trix/, count: 0
  end

  test "renders email_subscription tag" do
    @blog.update!(email_subscriptions_enabled: true)
    # Joel user already has an active subscription via fixtures

    page = @blog.pages.create!(title: "Subscribe", content: "{{ email_subscription }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select ".email-subscriber-form"
  end

  test "handles unknown tag gracefully" do
    page = @blog.pages.create!(title: "Unknown", content: "{{ unknown_tag }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    # Unknown tag should appear literally
    assert_includes response.body, "{{ unknown_tag }}"
  end

  test "renders posts tag with multiple tags (OR logic)" do
    page = @blog.pages.create!(title: "Test Page", content: "{{ posts | tag: photography, technology }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    # Should show posts with EITHER tag
    assert_select "body", text: /Photography and Technology/
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /Created with Trix/
  end

  test "renders posts_by_year tag with multiple tags (OR logic)" do
    page = @blog.pages.create!(title: "Photography and Tech Archive", content: "{{ posts_by_year | tag: photography, technology }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Photography and Technology/
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /Created with Trix/
  end

  test "renders posts tag with multiple tags without spaces" do
    page = @blog.pages.create!(title: "Test", content: "{{ posts | tag: photography,technology }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    assert_select "body", text: /Photography and Technology/
    assert_select "body", text: /The Art of Street Photography/
    assert_select "body", text: /Created with Trix/
  end

  test "posts tag renders datetime not just date" do
    page = @blog.pages.create!(title: "Archive", content: "{{ posts }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    # Should render full datetime with time component (19:45), not midnight
    assert_select "time[datetime$='T19:45:00Z']"
  end

  test "posts_by_year tag renders datetime not just date" do
    page = @blog.pages.create!(title: "Archive", content: "{{ posts_by_year }}", status: :published)

    get blog_post_url(subdomain: @blog.subdomain, slug: page.slug)

    assert_response :success
    # Should render full datetime with time component (19:45), not midnight
    assert_select "time[datetime$='T19:45:00Z']"
  end
end
