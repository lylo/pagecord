require "test_helper"

class App::Posts::TrashControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @post = posts(:one)
  end

  test "should get trash index with discarded posts" do
    @post.discard!
    get app_posts_trash_index_path
    assert_response :success
    assert_match @post.display_title, response.body
  end

  test "should show empty trash message" do
    get app_posts_trash_index_path
    assert_response :success
    assert_match "Your trash is empty", response.body
  end

  test "should restore discarded post" do
    @post.discard!
    assert @post.discarded?

    delete app_posts_trash_path(@post)

    assert_redirected_to app_posts_trash_index_path
    assert_equal "Post was successfully restored", flash[:notice]
    assert_not @post.reload.discarded?
  end

  test "should not restore post belonging to another user" do
    other_post = blogs(:elliot).posts.create!(title: "Other post", content: "Content")
    other_post.discard!

    delete app_posts_trash_path(other_post)
    assert_response :not_found
  end
end
