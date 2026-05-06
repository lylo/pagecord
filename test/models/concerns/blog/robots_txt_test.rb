require "test_helper"

class Blog::RobotsTxtTest < ActiveSupport::TestCase
  test "generated robots txt preserves existing discoverable behavior" do
    robots_txt = blogs(:joel).generated_robots_txt(sitemap_url: "https://joel.example.com/sitemap.xml")

    assert_includes robots_txt, "User-agent: *\nAllow: /"
    assert_includes robots_txt, "Sitemap: https://joel.example.com/sitemap.xml"
    assert_includes robots_txt, "User-agent: GPTBot\nDisallow: /"
    assert_not_includes robots_txt, "Last updated:"
  end

  test "generated robots txt disallows all when search indexing is disabled" do
    blog = blogs(:joel)
    blog.allow_search_indexing = false

    assert_equal "User-agent: *\nDisallow: /\n", blog.generated_robots_txt(sitemap_url: "https://joel.example.com/sitemap.xml")
  end

  test "custom robots txt is only active for subscribers" do
    subscribed_blog = blogs(:joel)
    free_blog = blogs(:vivian)
    custom_robots_txt = "User-agent: Bubbles\nAllow: /\n"

    subscribed_blog.custom_robots_txt = custom_robots_txt
    free_blog.custom_robots_txt = custom_robots_txt

    assert_equal custom_robots_txt, subscribed_blog.robots_txt(sitemap_url: "https://joel.example.com/sitemap.xml")
    assert_includes free_blog.robots_txt(sitemap_url: "https://vivian.example.com/sitemap.xml"), "User-agent: GPTBot"
  end

  test "blank custom robots txt normalizes to nil" do
    blog = blogs(:joel)
    blog.update!(custom_robots_txt: "\r\n  \n")

    assert_nil blog.custom_robots_txt
  end

  test "custom robots txt allows crawl delay" do
    blog = blogs(:joel)
    blog.custom_robots_txt = "User-agent: Googlebot/2.1\nUser-agent: Mozilla+compatible\nCrawl-delay: 0.5\nDisallow: /private\n"

    assert blog.valid?
  end

  test "custom robots txt validation rejects unsafe or unsupported content" do
    invalid_values = [
      "Host: example.com\n",
      "User-agent: Bad Bot\nDisallow: /\n",
      "User-agent: *\nAllow: posts\n",
      "User-agent: *\nSitemap: javascript:alert(1)\n",
      "User-agent: *\nDisallow: /\u0000\n",
      "User-agent: *\nCrawl-delay: slowly\n"
    ]

    invalid_values.each do |value|
      blog = blogs(:joel)
      blog.custom_robots_txt = value

      assert_not blog.valid?, "#{value.inspect} should be invalid"
      assert blog.errors[:custom_robots_txt].any?
    end
  end

  test "custom robots txt validation rejects oversized content" do
    blog = blogs(:joel)
    blog.custom_robots_txt = "User-agent: *\n#{"# padding\n" * 1100}"

    assert_not blog.valid?
    assert_includes blog.errors[:custom_robots_txt], "is too long (maximum 10 KB)"
  end
end
