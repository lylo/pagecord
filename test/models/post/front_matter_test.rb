require "test_helper"

class Post::FrontMatterTest < ActiveSupport::TestCase
  test "maps every supported key to its post attribute" do
    yaml = <<~YAML
      title: Hello
      slug: hello
      published_at: '2024-06-15'
      canonical_url: https://example.com/post
      link_url: https://example.com/article
      locale: fr
      status: draft
      hidden: true
      tags: ruby
      open_graph_image: text
    YAML

    assert_equal({
      title: "Hello", slug: "hello", published_at: "2024-06-15",
      canonical_url: "https://example.com/post", link_url: "https://example.com/article",
      locale: "fr", status: "draft", hidden: "true", tags_string: "ruby", open_graph_image: "text"
    }, Post::FrontMatter.parse(yaml))
  end

  test "maps date to published_at" do
    attrs = Post::FrontMatter.parse("date: '2024-06-15'")
    assert_equal "2024-06-15", attrs[:published_at]
  end

  test "parses tags as array" do
    attrs = Post::FrontMatter.parse("tags:\n  - ruby\n  - rails")
    assert_equal "ruby, rails", attrs[:tags_string]
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
