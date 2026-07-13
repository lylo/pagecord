require "test_helper"

class Html::ExternalLinksInNewTabTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "opens external links in a new tab" do
    link = transformed_link(@blog, '<p><a href="https://example.org">Example</a></p>')

    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
  end

  test "opens protocol-relative external links in a new tab" do
    link = transformed_link(@blog, '<p><a href="//example.org/about">Example</a></p>')

    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
  end

  test "preserves existing rel tokens" do
    link = transformed_link(@blog, '<p><a href="https://example.org" rel="nofollow">Example</a></p>')

    assert_equal "_blank", link["target"]
    assert_equal "nofollow noopener", link["rel"]
  end

  test "leaves non-external links unchanged" do
    links = transformed_links(@blog, <<~HTML)
      <p>
        <a href="http://#{@blog.subdomain}.example.com/about">Internal</a>
        <a href="/about">Relative</a>
        <a href="#section">Fragment</a>
        <a href="mailto:hello@example.org">Email</a>
        <a href="tel:+441234567890">Phone</a>
      </p>
    HTML

    assert_equal 5, links.size
    assert links.all? { |link| link["target"].nil? }
    assert links.all? { |link| link["rel"].nil? }
  end

  test "leaves custom domain links unchanged" do
    blog = blogs(:annie)
    link = transformed_link(blog, '<p><a href="https://annie.blog/about">Internal</a></p>')

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  test "leaves custom domain www variant unchanged" do
    blog = blogs(:annie)
    link = transformed_link(blog, '<p><a href="https://www.annie.blog/about">Internal</a></p>')

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  test "leaves multi-part TLD custom domain www variant unchanged" do
    blog = blogs(:annie)
    blog.update!(custom_domain: "annie.co.uk")
    link = transformed_link(blog, '<p><a href="https://www.annie.co.uk/about">Internal</a></p>')

    assert_nil link["target"]
    assert_nil link["rel"]
  end

  private

    def transformed_link(blog, html)
      transformed_links(blog, html).first
    end

    def transformed_links(blog, html)
      result = Html::ExternalLinksInNewTab.new(blog).transform(html)
      Nokogiri::HTML::DocumentFragment.parse(result).css("a")
    end
end
