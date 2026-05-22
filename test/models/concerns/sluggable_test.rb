require "test_helper"

class SluggableTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "should generate a slug before creating a post" do
    post = @blog.posts.create!(title: "A New Post", content: "This is a test post")
    assert_equal "a-new-post", post.slug
  end

  test "should prevent a duplicate slug for the same blog" do
    post1 = @blog.posts.first
    post2 = @blog.posts.create!(title: "A New Post", content: "This is a test post")

    assert_raises do
      post1.update!(slug: post2.slug)
    end
  end

  test "should validate slug format" do
    post = @blog.posts.first

    assert_invalid_slug_format post, "Invalid Slug"
    assert_invalid_slug_format post, "-invalid-slug"
    assert_invalid_slug_format post, "invalid-slug-"
    assert_invalid_slug_format post, "invalid slug"
    assert_invalid_slug_format post, "invalid--slug"

    post.update(slug: "valid_slug_with_underscores")
    assert post.valid?

    post.update(slug: "valid-slug-with-hyphens")
    assert post.valid?

    post.update(slug: "mixed_slug-with_both")
    assert post.valid?
  end

  test "should generate slug from token if title is blank" do
    post = @blog.posts.create!(content: "Content without title")
    assert_equal post.token, post.slug
  end

  test "should preserve slug when title changes on persisted published post" do
    post = posts(:one)
    post.update!(status: :published)  # Ensure it's published
    original_slug = post.slug

    post.update!(title: "Updated Title")

    assert_equal original_slug, post.slug
  end

  test "should update slug when explicitly changed on persisted post" do
    post = posts(:one)

    post.update!(slug: "new-explicit-slug")

    assert_equal "new-explicit-slug", post.slug
  end

  test "should update slug when title changes on draft post" do
    post = posts(:one)
    post.update!(status: :draft)

    post.update!(title: "Updated Draft Title")

    assert_equal "updated-draft-title", post.slug
  end

  test "should preserve slug when title changes on published post" do
    post = posts(:one)
    post.update!(status: :published)
    original_slug = post.slug

    post.update!(title: "Updated Published Title")

    assert_equal original_slug, post.slug
  end

  test "should preserve custom slug when creating a new post" do
    post = @blog.posts.create!(title: "A New Post", content: "Content", slug: "my-custom-slug")
    assert_equal "my-custom-slug", post.slug
  end

  test "should preserve custom slug when creating a new draft post" do
    post = @blog.posts.create!(title: "A New Post", content: "Content", slug: "my-custom-slug", status: :draft)
    assert_equal "my-custom-slug", post.slug
  end

  test "should handle duplicate slugs by appending a unique identifier" do
    post1 = @blog.posts.create!(title: "Duplicate", content: "Content 1")
    post2 = @blog.posts.create!(title: "Duplicate", content: "Content 2")

    assert_equal "duplicate", post1.slug
    assert_not_equal post1.slug, post2.slug
    assert_match /^#{post1.slug}-[a-f0-9]+$/, post2.slug
  end

  test "should allow identical slugs across different blogs" do
    post1 = blogs(:joel).posts.first
    vivian = blogs(:vivian)
    post2 = vivian.posts.create!(title: post1.title, content: "Content 2")

    assert_equal post1.slug, post2.slug
  end

  test "should truncate long titles for slug generation" do
    long_title = "This is an extremely long title that should be truncated when generating the slug" * 3
    post = @blog.posts.create!(title: long_title, content: "Content")

    assert post.slug.length <= 100
    assert_equal post.title.parameterize.truncate(100, omission: ""), post.slug
  end

  test "should remove trailing hyphens from truncated slugs" do
    title = "Futurism: Companies That Tried to Save Money With AI Are Now Spending a Fortune Hiring People to Fix Its Mistakes"
    raw_slug = title.parameterize.truncate(100, omission: "")
    assert raw_slug.end_with?("-")

    post = @blog.posts.create!(title: title, content: "Content")

    assert_not post.slug.end_with?("-")
    assert post.valid?
  end

  test "should not replace apostrophes with hypens" do
    title = "it's just not cricket"
    post = @blog.posts.create!(title: title, content: "Content")

    assert_equal "its-just-not-cricket", post.slug
    assert post.valid?
  end

  test "should not allow reserved slugs" do
    Sluggable::RESERVED_SLUGS.each do |reserved_slug|
      post = @blog.posts.build(title: "Test", content: "Test")
      # Save first to get past initial slug generation
      post.save!

      # Now try to manually change to reserved slug
      post.slug = reserved_slug

      assert_not post.valid?, "Expected post with slug '#{reserved_slug}' to be invalid"
      assert_includes post.errors[:slug], "is reserved and cannot be used"
    end
  end

  test "should prevent posts slug from being generated" do
    post = @blog.posts.create!(title: "Posts", content: "This should not get the slug 'posts'")
    assert_not_equal "posts", post.slug
    assert_match /^posts-[a-f0-9]+$/, post.slug
  end

  private

    def assert_invalid_slug_format(post, slug)
      post.update(slug: slug)
      assert_not post.valid?
      assert_includes post.errors[:slug], "can only contain lowercase letters, numbers, hyphens, and underscores"
    end
end
