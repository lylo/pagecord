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

  test "published at should be set on create for published posts" do
    post = blogs(:joel).posts.create! title: "my new post", content: "this is my new post", status: :published

    assert post.published_at.present?
  end

  test "published at should not be set on create for draft posts" do
    post = blogs(:joel).posts.create! title: "my new post", content: "this is my new post", status: :draft

    assert post.published_at.nil?
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
    assert_no_enqueued_jobs(only: GenerateOpenGraphImageJob) do
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

  test "should honor manual published_at when updating a published post" do
    post = posts(:one)
    manual_date = 1.year.ago.beginning_of_day
    post.update!(published_at: manual_date)
    assert_equal manual_date, post.published_at
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

  test "summary should return empty string when no text content" do
    blog = blogs(:joel)
    post = blog.posts.new(
      title: "Image Only Post",
      content: "<figure><img src='test.jpg'><figcaption>Test Image</figcaption></figure>"
    )

    summary = post.summary
    assert_equal "", summary
  end

  test "has_text_content? should return true for posts with text" do
    blog = blogs(:joel)
    post = blog.posts.create!(
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

  test "should set text_summary when post without title is saved" do
    blog = blogs(:joel)
    post = blog.posts.create!(content: "This is my post content that should be cached.")

    assert_equal "This is my post content that should be cached.", post.text_summary
  end

  test "should set text_summary even when post has a title" do
    blog = blogs(:joel)
    post = blog.posts.create!(title: "My Title", content: "This content should be cached.")

    assert_equal "This content should be cached.", post.text_summary
  end

  test "should update text_summary when content changes on untitled post" do
    blog = blogs(:joel)
    post = blog.posts.create!(content: "Original content")

    assert_equal "Original content", post.text_summary

    post.update!(content: "Updated content")
    post.reload

    assert_equal "Updated content", post.text_summary
  end

  test "display_title should use title when present" do
    blog = blogs(:joel)
    post = blog.posts.create!(title: "My Title", content: "Content")

    assert_equal "My Title", post.display_title
  end

  test "display_title should use text_summary when title is blank" do
    blog = blogs(:joel)
    post = blog.posts.create!(content: "This is my content that will be used as the title")

    assert_equal "This is my content that will be used as the title", post.display_title
  end

  test "display_title should truncate long text_summary" do
    blog = blogs(:joel)
    long_content = "This is a very long piece of content " * 10
    post = blog.posts.create!(content: long_content)

    assert_operator post.display_title.length, :<=, 64
    assert post.display_title.end_with?("...")
  end

  test "display_title should return Untitled when no title or text_summary" do
    blog = blogs(:joel)
    post = blog.posts.new(content: "<figure><img src='test.jpg'></figure>")

    assert_equal "Untitled", post.display_title
  end

  test "display_title should not include tags" do
    blog = blogs(:joel)
    post = blog.posts.create!(content: "<p>This is a test</p><p>{{ posts limit:5 }}</p>")

    assert_equal "This is a test", post.display_title
  end

  test "text_summary should preserve space between paragraphs" do
    blog = blogs(:joel)
    post = blog.posts.create!(
      content: "<p>First paragraph ends here.</p><p>Second paragraph starts here.</p>"
    )

    # Should have space between sentences from different paragraphs
    assert_equal "First paragraph ends here. Second paragraph starts here.", post.text_summary
    assert_includes post.text_summary, "here. Second"
  end

  test "text_summary should preserve space between headings and paragraphs" do
    blog = blogs(:joel)
    post = blog.posts.create!(
      content: "<h1>My Heading</h1><p>Paragraph text here.</p>"
    )

    assert_equal "My Heading Paragraph text here.", post.text_summary
    assert_includes post.text_summary, "Heading Paragraph"
  end

  test "text_summary should preserve space between list items" do
    blog = blogs(:joel)
    post = blog.posts.create!(
      content: "<ul><li>First item.</li><li>Second item.</li></ul>"
    )

    assert_equal "First item. Second item.", post.text_summary
    assert_includes post.text_summary, "item. Second"
  end

  test "text_summary should preserve space between divs" do
    blog = blogs(:joel)
    post = blog.posts.create!(
      content: "<div>First block.</div><div>Second block.</div>"
    )

    assert_equal "First block. Second block.", post.text_summary
    assert_includes post.text_summary, "block. Second"
  end

  # Locale tests
  test "locale should be nil by default" do
    blog = blogs(:joel)
    post = blog.posts.create!(content: "Test post")

    assert_nil post.locale
  end

  test "locale should accept valid locales" do
    blog = blogs(:joel)
    Localisable::SUPPORTED_LOCALES.each do |locale|
      post = blog.posts.build(content: "Test post", locale: locale)
      assert post.valid?, "Expected locale '#{locale}' to be valid"
    end
  end

  test "locale should reject invalid locales" do
    blog = blogs(:joel)
    post = blog.posts.build(content: "Test post", locale: "invalid")
    assert_not post.valid?
    assert_includes post.errors[:locale], "invalid is not a supported locale"
  end

  test "effective_locale should return post locale when set" do
    blog = blogs(:joel)
    post = blog.posts.create!(content: "Test post", locale: "es")

    assert_equal "es", post.effective_locale
  end

  test "effective_locale should return blog locale when post locale is nil" do
    blog = blogs(:joel)
    blog.update!(locale: "fr")
    post = blog.posts.create!(content: "Test post")

    assert_nil post.locale
    assert_equal "fr", post.effective_locale
  end
end
