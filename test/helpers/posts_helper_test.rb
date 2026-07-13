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

  private

    def rendered_link(html)
      Nokogiri::HTML::DocumentFragment.parse(html).css("a").first
    end
end
