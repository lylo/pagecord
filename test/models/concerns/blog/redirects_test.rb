require "test_helper"

class Blog::RedirectsTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "blank redirect rules normalize to nil" do
    @blog.update!(redirect_rules: "\r\n  \n")

    assert_nil @blog.redirect_rules
  end

  test "redirect rules normalize CRLF line endings" do
    @blog.update!(redirect_rules: "/old /new\r\n/older /newer\r\n")

    assert_equal "/old /new\n/older /newer\n", @blog.redirect_rules
  end

  test "unticking use_redirect_rules clears the rules" do
    @blog.update!(redirect_rules: "/old /new")
    @blog.update!(use_redirect_rules: false)

    assert_nil @blog.redirect_rules
  end

  test "comments and blank lines are allowed" do
    @blog.redirect_rules = "# moved from wordpress\n\n/old /new\n"

    assert @blog.valid?
  end

  test "rules must have exactly two tokens" do
    @blog.redirect_rules = "/old\n"

    assert_not @blog.valid?
    assert_includes @blog.errors[:redirect_rules], "has an invalid rule on line 1"
  end

  test "protocol-relative destinations are rejected" do
    @blog.redirect_rules = "/old //evil.com/path\n"

    assert_not @blog.valid?
    assert_includes @blog.errors[:redirect_rules], "has an invalid rule on line 1"
  end

  test "rule paths must start with a slash" do
    @blog.redirect_rules = "/old /new\nold-path /new\n"

    assert_not @blog.valid?
    assert_includes @blog.errors[:redirect_rules], "has an invalid rule on line 2"
  end

  test "wildcard is only allowed at the end of the source" do
    @blog.redirect_rules = "/old/*/deep /new\n"

    assert_not @blog.valid?
    assert_includes @blog.errors[:redirect_rules], "has an invalid rule on line 1"
  end

  test "wildcard destination requires a wildcard source" do
    @blog.redirect_rules = "/old /new/*\n"

    assert_not @blog.valid?
    assert_includes @blog.errors[:redirect_rules], "has an invalid rule on line 1"
  end

  test "duplicate sources are rejected" do
    @blog.redirect_rules = "/old /new\n/OLD/ /elsewhere\n"

    assert_not @blog.valid?
    assert_includes @blog.errors[:redirect_rules], "has a duplicate source on line 2"
  end

  test "redirect rules are capped in size" do
    @blog.redirect_rules = "/a /b\n" * 6_000

    assert_not @blog.valid?
    assert @blog.errors[:redirect_rules].any? { |e| e.include?("is too long") }
  end

  test "resolves an exact rule" do
    @blog.redirect_rules = "/old-path /new-path"

    assert_equal "/new-path", @blog.resolve_redirect("/old-path")
  end

  test "rule matching ignores case and trailing slashes" do
    @blog.redirect_rules = "/old-path /new-path"

    assert_equal "/new-path", @blog.resolve_redirect("/Old-Path/")
  end

  test "resolves a wildcard rule with substitution" do
    @blog.redirect_rules = "/blog/* /*"

    assert_equal "/my-post", @blog.resolve_redirect("/blog/my-post")
  end

  test "wildcard destination without a star discards the capture" do
    @blog.redirect_rules = "/archive/* /posts"

    assert_equal "/posts", @blog.resolve_redirect("/archive/2019/anything")
  end

  test "wildcard substitution never produces a protocol-relative URL" do
    @blog.redirect_rules = "/blog/* /*"

    assert_nil @blog.resolve_redirect("/blog//evil.com")
  end

  test "skips a rule that redirects to itself" do
    @blog.redirect_rules = "/gone /gone"

    assert_nil @blog.resolve_redirect("/gone")
  end

  test "skips a wildcard rule that resolves to the request path" do
    @blog.redirect_rules = "/blog/* /blog/*"

    assert_nil @blog.resolve_redirect("/blog/my-post")
  end

  test "explicit rules win over the slug fallback" do
    post = posts(:one)
    @blog.redirect_rules = "/blog/#{post.slug} /somewhere-else"

    assert_equal "/somewhere-else", @blog.resolve_redirect("/blog/#{post.slug}")
  end

  test "falls back to the slug for prefixed paths" do
    post = posts(:one)

    assert_equal "/#{post.slug}", @blog.resolve_redirect("/blog/#{post.slug}")
  end

  test "falls back to the slug for dated paths" do
    post = posts(:one)

    assert_equal "/#{post.slug}", @blog.resolve_redirect("/2024/01/01/#{post.slug}")
  end

  test "fallback strips an html suffix and trailing slash" do
    post = posts(:one)

    assert_equal "/#{post.slug}", @blog.resolve_redirect("/blog/#{post.slug}.html")
    assert_equal "/#{post.slug}", @blog.resolve_redirect("/blog/#{post.slug}/")
  end

  test "fallback matches pages" do
    page = posts(:about)

    assert_equal "/#{page.slug}", @blog.resolve_redirect("/site/#{page.slug}")
  end

  test "fallback matches hidden posts" do
    post = @blog.posts.create!(title: "Hidden", content: "Hidden", status: :published, hidden: true)

    assert_equal "/#{post.slug}", @blog.resolve_redirect("/blog/#{post.slug}")
  end

  test "fallback ignores drafts" do
    assert_nil @blog.resolve_redirect("/blog/#{posts(:joel_draft).slug}")
  end

  test "fallback ignores single-segment paths" do
    assert_nil @blog.resolve_redirect("/#{posts(:one).slug}-missing")
  end

  test "fallback ignores unknown slugs" do
    assert_nil @blog.resolve_redirect("/blog/no-such-post")
  end

  test "fallback redirects common feed paths" do
    assert_equal "/feed.xml", @blog.resolve_redirect("/blog/feed")
    assert_equal "/feed.xml", @blog.resolve_redirect("/blog/feed.xml")
    assert_equal "/feed.xml", @blog.resolve_redirect("/2024/rss.xml")
  end
end
