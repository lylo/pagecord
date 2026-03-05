require "test_helper"

class TrackPageViewJobTest < ActiveJob::TestCase
  test "should create a page view" do
    blog = blogs(:joel)
    post = posts(:one)

    assert_difference "PageView.count", 1 do
      TrackPageViewJob.perform_now(
        blog.id,
        post.token,
        "10.0.0.100",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "/test-path",
        "https://google.com",
        "US"
      )
    end

    view = PageView.last
    assert_equal blog, view.blog
    assert_equal post, view.post
    assert_equal "/test-path", view.path
    assert_equal "google.com", view.referrer_domain
    assert_equal "US", view.country
  end

  test "should handle missing blog gracefully" do
    assert_no_difference "PageView.count" do
      TrackPageViewJob.perform_now(999999, nil, "10.0.0.1", "Mozilla/5.0", "/", nil, nil)
    end
  end

  test "should handle nil post_token" do
    blog = blogs(:joel)

    assert_difference "PageView.count", 1 do
      TrackPageViewJob.perform_now(
        blog.id,
        nil,
        "10.0.0.101",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "/",
        nil,
        nil
      )
    end

    assert_nil PageView.last.post
  end
end
