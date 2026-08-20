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
    assert_includes html, %(<pre data-language="ruby">)
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

  test "renders a plain blockquote" do
    _attrs, html = Post::Markdown.render("> Just a quote")
    assert_includes html, "<blockquote>\n<p>Just a quote</p>"
    assert_not_includes html, "data-callout"
  end

  test "renders an obsidian callout with a title" do
    _attrs, html = Post::Markdown.render("> [!note] Title here\n> Some body text")

    assert_includes html, %(<aside data-callout="note">)
    assert_includes html, %(<p data-callout-title>Title here</p>)
    assert_includes html, "<p>Some body text</p>"
    assert_not_includes html, "[!note]"
  end

  test "defaults the callout title to the type" do
    _attrs, html = Post::Markdown.render("> [!warning]\n> Watch out")

    assert_includes html, %(<aside data-callout="warning">)
    assert_includes html, %(<p data-callout-title>Warning</p>)
    assert_includes html, "<p>Watch out</p>"
  end

  test "renders a callout with a title and no body" do
    _attrs, html = Post::Markdown.render("> [!tip] Just the title")

    assert_includes html, %(<p data-callout-title>Just the title</p>)
    assert_not_includes html, "<p></p>"
  end

  test "keeps the rest of a multi paragraph callout" do
    _attrs, html = Post::Markdown.render("> [!important] Heads up\n> First para\n>\n> Second para")

    assert_includes html, %(<aside data-callout="tip">)
    assert_includes html, "<p>First para</p>"
    assert_includes html, "<p>Second para</p>"
  end

  test "folds obsidian aliases onto the type they render as" do
    _attrs, html = Post::Markdown.render("> [!caution] Careful\n> Body")

    assert_includes html, %(<aside data-callout="warning">)
    assert_includes html, %(<p data-callout-title>Careful</p>)
  end

  test "titles an untitled callout with the type as written, not the canonical one" do
    _attrs, html = Post::Markdown.render("> [!important]\n> Body")

    assert_includes html, %(<aside data-callout="tip">)
    assert_includes html, %(<p data-callout-title>Important</p>)
  end

  test "keeps adjacent callouts separate" do
    _attrs, html = Post::Markdown.render("> [!note] First\n> One\n\n> [!warning] Second\n> Two")

    assert_includes html, %(<aside data-callout="note">)
    assert_includes html, %(<aside data-callout="warning">)
    assert_equal 2, html.scan("<aside").size
    assert_not_includes html, "[!warning]"
  end

  test "keeps a plain quote that precedes a callout separate" do
    _attrs, html = Post::Markdown.render("> Just a quote\n\n> [!tip] Then a callout\n> Body")

    assert_includes html, "<blockquote>\n<p>Just a quote</p>"
    assert_includes html, %(<aside data-callout="tip">)
  end

  test "supports nested callouts" do
    _attrs, html = Post::Markdown.render("> [!note] Outer\n> Outer body\n> > [!tip] Inner\n> > Inner body")

    fragment = Nokogiri::HTML::DocumentFragment.parse(html)
    assert_equal 1, fragment.css(%(aside[data-callout="note"] aside[data-callout="tip"])).size
  end

  # Redcarpet renders this and two separate quotes to identical HTML, so the two
  # sources cannot be told apart. We favour the callout reading; Obsidian would
  # keep a mid-quote marker as literal text.
  test "splits a marker paragraph out of a quoted block into its own callout" do
    _attrs, html = Post::Markdown.render("> plain first\n>\n> [!note] Mid-quote marker\n> body")

    assert_includes html, "<blockquote>\n<p>plain first</p>\n</blockquote>"
    assert_includes html, %(<aside data-callout="note">)
  end

  test "renders inline markdown in a callout title" do
    _attrs, html = Post::Markdown.render("> [!caution] **Bold** title\n> Body")
    assert_includes html, %(<p data-callout-title><strong>Bold</strong> title</p>)
  end

  test "matches callout types case insensitively" do
    _attrs, html = Post::Markdown.render("> [!NOTE] Shouting\n> Body")
    assert_includes html, %(<aside data-callout="note">)
  end

  test "callout attributes survive sanitizing" do
    _attrs, html = Post::Markdown.render("> [!note] Title here\n> Some body text")

    assert_includes ActionText::Content.new(html).to_rendered_html_with_layout, %(data-callout="note")
    assert_includes Html::Sanitize.new.transform(html), %(data-callout="note")
  end

  test "falls back to note for an unrecognised type, as obsidian does" do
    _attrs, html = Post::Markdown.render("> [!bogus] Unknown type\n> Body")

    assert_includes html, %(<aside data-callout="note">)
    assert_includes html, %(<p data-callout-title>Unknown type</p>)
    assert_includes html, "<p>Body</p>"
    assert_not_includes html, "[!bogus]"
  end

  test "titles an untitled unrecognised type with the word that was typed" do
    _attrs, html = Post::Markdown.render("> [!bogus]\n> Body")

    assert_includes html, %(<aside data-callout="note">)
    assert_includes html, %(<p data-callout-title>Bogus</p>)
  end

  test "renders a footnote reference and its note" do
    _attrs, html = Post::Markdown.render("Some text[^1].\n\n[^1]: The note.")

    assert_includes html, %(<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>)
    assert_includes html, %(<ol data-footnotes>)
    assert_includes html, %(<li id="fn-1"><p>The note.</p>)
  end

  test "numbers footnotes in the order they are referenced" do
    _attrs, html = Post::Markdown.render("First[^b] then[^a].\n\n[^a]: Note A.\n[^b]: Note B.")
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    assert_equal [ "1", "2" ], doc.css("sup[data-footnote-ref]").map(&:text)
    assert_equal [ "Note B.", "Note A." ], doc.css("ol[data-footnotes] li p").map(&:text)
  end

  test "renders markdown inside a footnote" do
    _attrs, html = Post::Markdown.render("Text[^1].\n\n[^1]: A **bold** note.")
    assert_includes html, "<strong>bold</strong>"
  end

  test "keeps every paragraph of a multi paragraph footnote" do
    _attrs, html = Post::Markdown.render("Text[^1].\n\n[^1]: First para.\n\n    Second para.")
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    assert_equal [ "First para.", "Second para." ], doc.css("ol[data-footnotes] li p").map(&:text)
  end

  test "renders a footnote referenced twice as two markers sharing one note" do
    _attrs, html = Post::Markdown.render("Once[^1] and again[^1].\n\n[^1]: The shared note.")
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    assert_equal 2, doc.css("sup[data-footnote-ref='1']").size
    assert_equal 1, doc.css("ol[data-footnotes] li").size
  end

  test "leaves a reference with no definition as written" do
    _attrs, html = Post::Markdown.render("Text[^missing] here.")

    assert_includes html, "[^missing]"
    assert_not_includes html, "data-footnote-ref"
  end

  test "drops a definition that is never referenced" do
    _attrs, html = Post::Markdown.render("Just text.\n\n[^unused]: Never referenced.")

    assert_not_includes html, "data-footnotes"
    assert_not_includes html, "Never referenced"
  end

  test "renders a footnote inside a callout" do
    _attrs, html = Post::Markdown.render("> [!note] Heads up\n> Body[^1].\n\n[^1]: The note.")
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    assert_equal 1, doc.css("aside[data-callout] sup[data-footnote-ref]").size
    assert_equal 1, doc.css("ol[data-footnotes] li").size
  end

  test "leaves an ordinary numbered list alone" do
    _attrs, html = Post::Markdown.render("1. one\n2. two")

    assert_includes html, "<ol>"
    assert_not_includes html, "data-footnotes"
  end

  test "footnote attributes survive sanitizing" do
    _attrs, html = Post::Markdown.render("Text[^1].\n\n[^1]: The note.")
    rendered = ActionText::Content.new(html).to_rendered_html_with_layout

    assert_includes rendered, %(data-footnote-ref="1")
    assert_includes rendered, %(id="fnref-1")
    assert_includes rendered, %(id="fn-1")
    assert_includes rendered, "data-footnotes"

    sanitized = Html::Sanitize.new.transform(html)
    assert_includes sanitized, %(data-footnote-ref="1")
    assert_includes sanitized, %(id="fn-1")
    assert_includes sanitized, "data-footnotes"
  end
end
