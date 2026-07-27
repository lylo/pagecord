require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  include CommentsHelper

  setup do
    @blog = blogs(:joel)
    @post = posts(:one)
    # The flag resolves off the blog owner, so granting it is what turns the
    # comment UI on — matching Posts::CommentsControllerTest.
    @blog.user.update!(features: @blog.user.features | [ "comments" ])
  end

  # The feed runs turbo_frame_top_controller, which rewrites links to target
  # _top. It must leave a link that has chosen its own frame alone, or clicking
  # comments navigates to the bare frame response instead of loading it in place.
  test "comments load into the frame from the feed" do
    use_subdomain(@blog.subdomain)
    visit "/"

    assert_selector ".h-feed"
    find("a[href='#{post_comments_path(@post)}']").click

    assert_selector "turbo-frame##{comments_frame_id(@post)} .comment-message", text: /Great post/
    # A full page navigation would have replaced the feed with the bare frame
    assert_selector ".h-feed"
  end
end
