require "test_helper"

class App::Comments::ClosuresControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @post = posts(:one)
    login_as @user
  end

  test "creating a closure closes comments without leaving the comment" do
    post app_comment_closure_path(post_comments(:approved))

    assert_not @post.reload.comments_open?
    assert_redirected_to app_comment_path(post_comments(:approved))
  end

  test "destroying a closure reopens comments" do
    @post.close_comments!

    delete app_comment_closure_path(post_comments(:approved))

    assert @post.reload.comments_open?
    assert_redirected_to app_comment_path(post_comments(:approved))
  end

  # The property a toggle could never have
  test "closing twice leaves comments closed" do
    2.times { post app_comment_closure_path(post_comments(:approved)) }

    assert_not @post.reload.comments_open?
  end
end
