require "application_system_test_case"

class UpvotePostTest < ApplicationSystemTestCase
  test "user can upvote a post" do
    blog = blogs(:joel)
    blog.update!(show_upvotes: true)

    post = posts(:two)  # Use specific post with no fixture upvotes
    assert_equal 0, post.upvotes.count

    use_subdomain(blog.subdomain)
    visit blog_post_path(post.slug)

    find("a.upvote").click
    assert_selector "a.upvote[data-upvoted]"
    assert_equal 1, post.upvotes.reload.count

    # Second click is idempotent (same visitor can't upvote twice)
    find("a.upvote").click
    assert_selector "a.upvote[data-upvoted]"
    assert_equal 1, post.upvotes.reload.count
  end
end
