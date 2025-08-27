require "application_system_test_case"

class AnalyticsTest < ApplicationSystemTestCase
  def setup
    @blog = blogs(:joel)
    @post = posts(:one)

    use_subdomain(@blog.subdomain)
  end

  test "blog index page tracks analytics via Stimulus" do
    visit blog_posts_path

    # Check that the analytics controller is present in the DOM
    assert_selector '[data-controller="analytics"]', visible: false
    assert_selector "[data-analytics-hit-url-value]", visible: false

    # Verify the hit URL is correct
    hit_url = find('[data-controller="analytics"]', visible: false)["data-analytics-hit-url-value"]
    assert_includes hit_url, "/hit"
  end

  test "individual post page tracks analytics with post token" do
    assert_difference("PageView.count", 1) do
      visit blog_post_path(@post.slug)

      # Wait for the analytics request to complete
      sleep 0.2
    end

    # Check that analytics controller has post token
    assert_selector '[data-controller="analytics"]', visible: false
    assert_selector "[data-analytics-post-token-value]", visible: false

    # Verify post token is present
    post_token = find('[data-controller="analytics"]', visible: false)["data-analytics-post-token-value"]
    assert_equal @post.token, post_token

    # Verify the pageview was created with correct attributes
    pageview = PageView.last
    assert_equal @blog, pageview.blog
    assert_equal @post, pageview.post
    assert pageview.is_unique?
  end

  test "analytics works on Turbo navigation" do
    visit blog_posts_path

    click_link href: "/#{@post.slug}"

    # Should now have post-specific analytics tracking
    assert_selector '[data-controller="analytics"]', visible: false
    assert_selector "[data-analytics-post-token-value]", visible: false

    post_token = find('[data-controller="analytics"]', visible: false)["data-analytics-post-token-value"]
    assert_equal @post.token, post_token
  end
end
