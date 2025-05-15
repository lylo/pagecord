require "application_system_test_case"

class UpvotePostTest < ApplicationSystemTestCase
  test "user can upvote a post" do
    blog = blogs(:joel)

    post = blog.posts.published.first
    initial_upvotes = post.upvotes.count

    visit post_without_title_path(post.blog.name, post.token)

    within "turbo-frame##{dom_id(post, :upvotes)}" do
      find("button[type=submit]").click
    end

    assert initial_upvotes + 1, post.reload.upvotes.count

    within "turbo-frame##{dom_id(post, :upvotes)}" do
      find("button[type=submit]").click
    end

    assert initial_upvotes, post.reload.upvotes.count
  end
end
