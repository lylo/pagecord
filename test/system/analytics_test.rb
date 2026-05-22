require "application_system_test_case"

class AnalyticsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  def setup
    @blog = blogs(:joel)
    @post = posts(:one)

    use_subdomain(@blog.subdomain)
  end

  test "blog index page tracks analytics via Stimulus" do
    visit blog_posts_path

    # Check that the pageview controller is present in the DOM
    assert_selector '[data-controller="pv"]', visible: false
    assert_selector "[data-pv-pth-value]", visible: false

    # Verify the hit URL is correct
    hit_url = find('[data-controller="pv"]', visible: false)["data-pv-pth-value"]
    assert_includes hit_url, "/pv"
  end

  test "individual post page tracks analytics with post token" do
    assert_difference("PageView.count", 1) do
      perform_enqueued_jobs do
        visit blog_post_path(@post.slug)

        # Wait for the page view request to complete
        sleep 1
      end
    end

    # Check that pageview controller has post token
    assert_selector '[data-controller="pv"]', visible: false
    assert_selector "[data-pv-post-token-value]", visible: false

    # Verify post token is present
    post_token = find('[data-controller="pv"]', visible: false)["data-pv-post-token-value"]
    assert_equal @post.token, post_token

    # Verify the pageview was created with correct attributes
    pageview = PageView.last
    assert_equal @blog, pageview.blog
    assert_equal @post, pageview.post
    assert pageview.is_unique?
  end

  test "page view works on Turbo navigation" do
    visit blog_posts_path

    click_link href: "/#{@post.slug}"

    # Should now have post-specific page view tracking
    assert_selector '[data-controller="pv"]', visible: false
    assert_selector "[data-pv-post-token-value]", visible: false

    post_token = find('[data-controller="pv"]', visible: false)["data-pv-post-token-value"]
    assert_equal @post.token, post_token
  end
end
