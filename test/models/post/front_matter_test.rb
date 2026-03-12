require "test_helper"

class Post::FrontMatterTest < ActiveSupport::TestCase
  test "parses title" do
    attrs = Post::FrontMatter.parse("title: Hello World")
    assert_equal "Hello World", attrs[:title]
  end

  test "parses slug" do
    attrs = Post::FrontMatter.parse("slug: hello-world")
    assert_equal "hello-world", attrs[:slug]
  end

  test "parses status" do
    attrs = Post::FrontMatter.parse("status: draft")
    assert_equal "draft", attrs[:status]
  end

  test "parses published_at" do
    attrs = Post::FrontMatter.parse("published_at: '2024-06-15'")
    assert_equal "2024-06-15", attrs[:published_at]
  end

  test "maps date to published_at" do
    attrs = Post::FrontMatter.parse("date: '2024-06-15'")
    assert_equal "2024-06-15", attrs[:published_at]
  end

  test "parses tags as array" do
    attrs = Post::FrontMatter.parse("tags:\n  - ruby\n  - rails")
    assert_equal "ruby, rails", attrs[:tags_string]
  end

  test "parses tags as single value" do
    attrs = Post::FrontMatter.parse("tags: ruby")
    assert_equal "ruby", attrs[:tags_string]
  end

  test "parses canonical_url" do
    attrs = Post::FrontMatter.parse("canonical_url: https://example.com/post")
    assert_equal "https://example.com/post", attrs[:canonical_url]
  end

  test "parses hidden" do
    attrs = Post::FrontMatter.parse("hidden: true")
    assert_equal "true", attrs[:hidden]
  end

  test "parses locale" do
    attrs = Post::FrontMatter.parse("locale: fr")
    assert_equal "fr", attrs[:locale]
  end

  test "ignores unknown keys" do
    attrs = Post::FrontMatter.parse("title: Hello\nunknown: value")
    assert_equal({ title: "Hello" }, attrs)
  end

  test "returns empty hash for empty yaml" do
    attrs = Post::FrontMatter.parse("")
    assert_equal({}, attrs)
  end

  test "raises InvalidError for malformed yaml" do
    assert_raises(Post::FrontMatter::InvalidError) do
      Post::FrontMatter.parse("title: [invalid\nyaml: :")
    end
  end
end
