require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include PostsHelper

  setup do
    @blog = blogs(:joel)
  end

  test "render_post_content leaves links unchanged when setting is disabled" do
    post = @blog.posts.build(content: '<p><a href="https://example.org">Example</a></p>')

    link = rendered_link(render_post_content(post))

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  test "render_post_content opens external authored links in new tab" do
    @blog.update!(external_links_in_new_tab: true)
    post = @blog.posts.build(content: '<p><a href="https://example.org">Example</a></p>')

    link = rendered_link(render_post_content(post))

    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
  end

  test "render_post_content opens auto-linked external URLs in new tab" do
    @blog.update!(external_links_in_new_tab: true)
    post = @blog.posts.build(content: "<p>Visit https://example.org</p>")

    link = rendered_link(render_post_content(post))

    assert_equal "https://example.org", link["href"]
    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
  end

  test "render_post_excerpt opens external links in new tab" do
    @blog.update!(external_links_in_new_tab: true)
    post = @blog.posts.build(content: "<p>Visit https://example.org</p><p>{{ more }}</p><p>Rest</p>")

    link = rendered_link(render_post_excerpt(post))

    assert_equal "https://example.org", link["href"]
    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
  end

  test "render_post_content leaves non-external links unchanged" do
    @blog.update!(external_links_in_new_tab: true)
    post = @blog.posts.build(content: <<~HTML)
      <p>
        <a href="http://#{@blog.subdomain}.example.com/about">Internal</a>
        <a href="/about">Relative</a>
        <a href="#section">Fragment</a>
        <a href="mailto:hello@example.org">Email</a>
        <a href="tel:+441234567890">Phone</a>
      </p>
    HTML

    links = rendered_links(render_post_content(post))

    assert_equal 5, links.size
    assert links.all? { |link| link["target"].nil? }
    assert links.all? { |link| link["rel"].nil? }
  end

  test "render_post_content leaves custom domain links unchanged" do
    blog = blogs(:annie)
    blog.update!(external_links_in_new_tab: true)
    post = blog.posts.build(content: '<p><a href="https://annie.blog/about">Internal</a></p>')

    link = rendered_link(render_post_content(post))

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  test "render_post_content leaves custom domain www variant unchanged" do
    blog = blogs(:annie)
    blog.update!(external_links_in_new_tab: true)
    post = blog.posts.build(content: '<p><a href="https://www.annie.blog/about">Internal</a></p>')

    link = rendered_link(render_post_content(post))

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  test "render_post_content leaves multi-part TLD custom domain www variant unchanged" do
    blog = blogs(:annie)
    blog.update!(external_links_in_new_tab: true, custom_domain: "annie.co.uk")
    post = blog.posts.build(content: '<p><a href="https://www.annie.co.uk/about">Internal</a></p>')

    link = rendered_link(render_post_content(post))

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  test "render_post_content opens protocol-relative external links in new tab" do
    @blog.update!(external_links_in_new_tab: true)
    post = @blog.posts.build(content: '<p><a href="//example.org/about">Example</a></p>')

    link = rendered_link(render_post_content(post))

    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
  end

  test "preserves existing rel tokens" do
    link = rendered_link(Html::ExternalLinksInNewTab.new(@blog).transform('<p><a href="https://example.org" rel="nofollow">Example</a></p>'))

    assert_equal "_blank", link["target"]
    assert_equal "nofollow noopener", link["rel"]
  end

  private

    def rendered_link(html)
      rendered_links(html).first
    end

    def rendered_links(html)
      Nokogiri::HTML::DocumentFragment.parse(html).css("a")
    end
end
