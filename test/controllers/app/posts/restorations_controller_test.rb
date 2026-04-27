require "test_helper"

class App::Posts::RestorationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @post = posts(:one)
  end

  test "should restore discarded post" do
    @post.discard!
    assert @post.discarded?

    post app_post_restoration_path(@post)

    assert_redirected_to app_posts_trash_path
    assert_equal "Post was successfully restored", flash[:notice]
    assert_not @post.reload.discarded?
  end

  test "should not restore post belonging to another user" do
    other_post = blogs(:elliot).posts.create!(title: "Other post", content: "Content")
    other_post.discard!

    post app_post_restoration_path(other_post)
    assert_response :not_found
  end
end
