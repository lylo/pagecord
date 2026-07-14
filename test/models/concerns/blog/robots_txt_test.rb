require "test_helper"

class Blog::RobotsTxtTest < ActiveSupport::TestCase
  test "custom robots txt is only active for subscribers" do
    subscribed_blog = blogs(:joel)
    free_blog = blogs(:vivian)
    custom_robots_txt = "User-agent: Bubbles\nAllow: /\n"

    subscribed_blog.custom_robots_txt = custom_robots_txt
    free_blog.custom_robots_txt = custom_robots_txt

    assert subscribed_blog.custom_robots_txt_active?
    assert_not free_blog.custom_robots_txt_active?
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

  test "custom robots txt allows user agents with spaces" do
    blog = blogs(:joel)
    blog.custom_robots_txt = "User-agent: Kangaroo Bot\nDisallow: /\n"

    assert blog.valid?
  end

  test "default crawler rules are valid custom robots txt" do
    blog = blogs(:joel)
    blog.custom_robots_txt = ApplicationController.render(partial: "blogs/robots/ai_training_crawlers", formats: :text)

    assert blog.valid?
  end

  test "custom robots txt validation rejects unsafe or unsupported content" do
    invalid_values = [
      "Host: example.com\n",
      "Sitemap: https://example.com/sitemap.xml\n",
      "User-agent: *\nAllow: posts\n",
      "User-agent: *\nDisallow: /\u0007\n",
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
    blog.custom_robots_txt = "User-agent: *\n#{"# padding\n" * 3500}"

    assert_not blog.valid?
    assert_includes blog.errors[:custom_robots_txt], "is too long (maximum 32 KB)"
  end
end
