require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "should generate a token on create" do
    post = Post.create(blog: blogs(:joel), title: "a new post", content: "content")
    assert post.token.present?
  end

  test "should be valid with body" do
    @post = Post.new(blog: blogs(:joel), content: "Test post")
    assert @post.valid?
  end

  test "should not be valid without body or title" do
    @post = Post.new(blog: blogs(:joel), content: nil, title: nil)
    assert_not @post.valid?
  end

  test "published at should be set on create if not provided" do
    post = blogs(:joel).posts.create! title: "my new post", content: "this is my new post"

    assert_equal post.created_at, post.published_at
  end

  test "published at should be set" do
    published_at = 1.day.ago
    post = blogs(:joel).posts.create! title: "my new post", content: "this is my new post", published_at: published_at

    assert_equal published_at.to_time.to_i, post.published_at.to_time.to_i
  end

  test "should exclude future-dated posts from visible scope" do
    post = Post.create(blog: blogs(:joel), title: "a new post", published_at: 1.day.from_now)
    assert_not Post.visible.include?(post)
  end

  test "should exclude draft posts from visible scope" do
    post = Post.create(blog: blogs(:joel), title: "a new post", content: "content", status: :draft)
    assert_not Post.visible.include?(post)
  end

  test "should exclude draft posts from published scope" do
    post = Post.create(blog: blogs(:joel), title: "a new post", content: "content", status: :draft)
    assert_not Post.published.include?(post)
  end

  test "should include draft posts in draft scope" do
    post = Post.create(blog: blogs(:joel), title: "a new post", content: "content", status: :draft)
    assert Post.draft.include?(post)
    assert Post.draft.include?(posts(:joel_draft))
  end

  test "post with blank title and body should be invalid" do
    assert_not blogs(:joel).posts.build(title: "", content: "").valid?
  end

  test "destroying a post should destroy digest posts" do
    assert_difference "DigestPost.count", -1 do
      posts(:one).destroy
    end
  end

  # Page-related tests
  test "should create page" do
    blog = blogs(:joel)
    page = blog.posts.build(title: "Test Page", content: "Page content", is_page: true)
    assert page.save
    assert page.page?
    assert_not page.post?
  end

  test "should create post" do
    blog = blogs(:joel)
    post = blog.posts.build(title: "Test Blog Post", content: "Post content", is_page: false)
    assert post.save
    assert post.post?
    assert_not post.page?
  end

  test "should scope pages correctly" do
    blog = blogs(:joel)
    page = blog.posts.create!(title: "Test About Page", content: "About content", is_page: true, status: :published)
    post = blog.posts.create!(title: "Test Post", content: "Post content", is_page: false, status: :published)

    assert_includes blog.pages, page
    assert_not_includes blog.pages, post
    assert_includes blog.posts, post
    assert_not_includes blog.posts, page
  end

  test "should filter navigation pages" do
    blog = blogs(:joel)
    visible_page = blog.posts.create!(
      title: "Test Navigation Page",
      content: "Navigation page content",
      is_page: true,
      show_in_navigation: true,
      status: :published,
      published_at: 1.day.ago
    )
    non_nav_page = blog.posts.create!(
      title: "Hidden Page",
      content: "Hidden content",
      is_page: true,
      show_in_navigation: false,
      status: :published,
      published_at: 1.day.ago
    )

    assert_includes blog.pages.navigation_pages.visible, visible_page
    assert_not_includes blog.pages.navigation_pages.visible, non_nav_page
  end

  test "show_in_navigation defaults to true" do
    blog = blogs(:joel)
    page = blog.posts.build(is_page: true)
    assert page.show_in_navigation
  end

  test "is_page defaults to false" do
    blog = blogs(:joel)
    post = blog.posts.build
    assert_not post.is_page
  end

  test "pages should not trigger open graph image job" do
    blog = blogs(:joel)
    assert_no_enqueued_jobs do
      blog.posts.create!(title: "Test OpenGraph Page", content: "Page content", is_page: true)
    end
  end

  test "fixture pages should be correctly configured" do
    about_page = posts(:about)
    assert about_page.page?
    assert about_page.show_in_navigation?
    assert_equal "about", about_page.slug
    assert_equal blogs(:joel), about_page.blog

    draft_page = posts(:draft_page)
    assert draft_page.page?
    assert_not draft_page.show_in_navigation?
    assert draft_page.draft?
  end

  test "should include Taggable concern" do
    post = Post.new(blog: blogs(:joel), content: "Test post")
    assert post.respond_to?(:tag_list)
    assert post.respond_to?(:tags_string)
    assert post.respond_to?(:tags_string=)
    assert Post.respond_to?(:tagged_with)
    assert Post.respond_to?(:all_tags)
  end

  test "summary should return truncated text content" do
    blog = blogs(:joel)
    post = blog.posts.create!(
      title: "Test Post",
      content: "This is a long post with lots of text content that should be truncated when we call the summary method with a limit."
    )

    summary = post.summary(limit: 50)
    assert_equal "This is a long post with lots of text content...", summary
  end

  test "summary should return 'Untitled' when no text content" do
    blog = blogs(:joel)
    post = blog.posts.new(
      title: "Image Only Post",
      content: "<figure><img src='test.jpg'><figcaption>Test Image</figcaption></figure>"
    )

    summary = post.summary
    assert_equal "Untitled", summary
  end

  test "has_text_content? should return true for posts with text" do
    blog = blogs(:joel)
    post = blog.posts.new(
      title: "Text Post",
      content: "This post has meaningful text content."
    )

    assert post.has_text_content?
  end

  test "has_text_content? should return false for image-only posts" do
    blog = blogs(:joel)
    post = blog.posts.new(
      title: "Image Only Post",
      content: "<figure><img src='test.jpg'></figure>"
    )

    assert_not post.has_text_content?
  end

  test "has_text_content? should return false for URL-only posts" do
    blog = blogs(:joel)
    post = blog.posts.new(
      title: "URL Only Post",
      content: "https://example.com"
    )

    assert_not post.has_text_content?
  end

  test "should exclude hidden posts from visible scope" do
    post = Post.create(blog: blogs(:joel), title: "hidden post", content: "content", hidden: true)
    assert_not Post.visible.include?(post)
  end

  test "should include non-hidden posts in visible scope" do
    post = Post.create(blog: blogs(:joel), title: "public post", content: "content", hidden: false)
    assert Post.visible.include?(post)
  end

  test "pages require a title" do
    blog = blogs(:joel)
    page = blog.posts.new(content: "Page content", is_page: true, title: "")
    assert_not page.valid?
    assert_includes page.errors[:title], "can't be blank"
  end
end
