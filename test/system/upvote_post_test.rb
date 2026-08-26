require "application_system_test_case"

class UpvotePostTest < ApplicationSystemTestCase
  test "user can upvote a post" do
    blog = blogs(:joel)
    blog.update!(show_upvotes: true)

    post = posts(:two)  # Use specific post with no fixture upvotes
    assert_equal 0, post.upvotes.count

    use_subdomain(blog.subdomain)
    visit blog_post_path(post.slug)

    find("button.upvote").click
    assert_selector ".upvote-heart[style*='fill']"  # JS sets fill color immediately
    wait_for { post.upvotes.reload.count == 1 }
    assert_equal 1, post.upvotes.reload.count

    # Second click has no effect (already upvoted)
    find("button.upvote").click
    wait_for { post.upvotes.reload.count >= 1 }
    assert_equal 1, post.upvotes.reload.count

    # Upvote state persists after page refresh
    visit blog_post_path(post.slug)
    assert_selector ".upvote-heart[style*='fill']"
  end

  private

    def wait_for(deadline: 5)
      limit = Time.current + deadline
      sleep 0.1 until yield || Time.current > limit
    end
end
