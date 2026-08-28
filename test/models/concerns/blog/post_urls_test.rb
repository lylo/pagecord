require "test_helper"

class Blog::PostUrlsTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "defaults to the flat format" do
    assert_equal "flat", @blog.post_url_format
    assert @blog.valid?
  end

  test "rejects unknown formats" do
    @blog.post_url_format = "nested"

    assert_not @blog.valid?
  end

  test "prefix format requires a prefix" do
    @blog.post_url_format = "prefix"
    @blog.post_url_prefix = nil

    assert_not @blog.valid?
    assert @blog.errors[:post_url_prefix].any?
  end

  test "prefix is normalized" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: " /Articles/ ")

    assert_equal "articles", @blog.post_url_prefix
  end

  test "reserved prefixes are rejected" do
    @blog.post_url_format = "prefix"

    Blog::PostUrls::RESERVED_PREFIXES.each do |reserved|
      @blog.post_url_prefix = reserved

      assert_not @blog.valid?, "expected #{reserved} to be reserved"
    end
  end

  test "prefixes with invalid characters are rejected" do
    @blog.post_url_format = "prefix"
    @blog.post_url_prefix = "my blog!"

    assert_not @blog.valid?
  end

  test "posts list path lives at the folder when one is set" do
    assert_equal "/posts", @blog.posts_list_path
    assert_equal "/posts?tag=travel", @blog.posts_list_path(tag: "travel")

    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    assert_equal "/notes", @blog.posts_list_path
    assert_equal "/notes?tag=travel", @blog.posts_list_path(tag: "travel")
  end

  test "dated format needs no prefix" do
    @blog.post_url_format = "dated"
    @blog.post_url_prefix = nil

    assert @blog.valid?
  end

  test "prefix cannot take a page's slug" do
    page = posts(:about)

    @blog.post_url_format = "prefix"
    @blog.post_url_prefix = page.slug

    assert_not @blog.valid?
    assert_equal [ "is already used by a page" ], @blog.errors[:post_url_prefix]
  end

  test "prefix may take a post's slug, since posts move into the folder" do
    post = @blog.posts.first

    @blog.post_url_format = "prefix"
    @blog.post_url_prefix = post.slug

    assert @blog.valid?
  end

  test "a discarded page does not block the prefix" do
    page = posts(:about)
    page.discard!

    @blog.post_url_format = "prefix"
    @blog.post_url_prefix = page.slug

    assert @blog.valid?
  end
end
