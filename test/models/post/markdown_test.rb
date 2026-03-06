require "test_helper"

class Post::MarkdownTest < ActiveSupport::TestCase
  test "renders markdown to html" do
    attrs, html = Post::Markdown.render("Hello **world**")
    assert_includes html, "<strong>world</strong>"
    assert_equal({}, attrs)
  end

  test "extracts front matter and renders body" do
    text = "---\ntitle: My Post\n---\nHello **world**"
    attrs, html = Post::Markdown.render(text)

    assert_equal "My Post", attrs[:title]
    assert_includes html, "<strong>world</strong>"
    assert_not_includes html, "---"
    assert_not_includes html, "My Post"
  end

  test "passes front matter attributes through to FrontMatter" do
    text = "---\ntitle: Hello\nslug: hello\ntags:\n  - ruby\n  - rails\nstatus: draft\n---\nBody"
    attrs, _html = Post::Markdown.render(text)

    assert_equal "Hello", attrs[:title]
    assert_equal "hello", attrs[:slug]
    assert_equal "ruby, rails", attrs[:tags_string]
    assert_equal "draft", attrs[:status]
  end

  test "handles markdown without front matter" do
    attrs, html = Post::Markdown.render("Just some text")
    assert_equal({}, attrs)
    assert_includes html, "Just some text"
  end

  test "handles incomplete front matter delimiters" do
    text = "---\ntitle: Hello\nNo closing delimiter"
    attrs, html = Post::Markdown.render(text)
    assert_equal({}, attrs)
    assert_includes html, "title: Hello"
  end

  test "renders fenced code blocks" do
    text = "```ruby\nputs 'hi'\n```"
    _attrs, html = Post::Markdown.render(text)
    assert_includes html, "<code"
  end

  test "renders tables" do
    text = "| a | b |\n|---|---|\n| 1 | 2 |"
    _attrs, html = Post::Markdown.render(text)
    assert_includes html, "<table>"
  end

  test "renders strikethrough" do
    _attrs, html = Post::Markdown.render("~~deleted~~")
    assert_includes html, "<del>deleted</del>"
  end

  test "renders autolinks" do
    _attrs, html = Post::Markdown.render("https://example.com")
    assert_includes html, "<a href"
  end
end
