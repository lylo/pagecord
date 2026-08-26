require "application_system_test_case"

class AnalyticsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  # The one thing only a browser can prove: the Stimulus controller actually
  # sends the beacon and a page view lands.
  test "visiting a post records a page view" do
    blog = blogs(:joel)
    post = posts(:one)
    use_subdomain(blog.subdomain)

    assert_difference("PageView.count", 1) do
      perform_enqueued_jobs do
        visit blog_post_path(post.slug)

        deadline = Time.current + 5
        sleep 0.1 until PageView.exists?(post_id: post.id) || Time.current > deadline
      end
    end

    pageview = PageView.last
    assert_equal blog, pageview.blog
    assert_equal post, pageview.post
    assert pageview.is_unique?
  end
end
