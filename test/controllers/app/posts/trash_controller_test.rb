require "test_helper"

class App::Posts::TrashControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @post = posts(:one)
  end

  test "should get trash with discarded posts" do
    @post.discard!
    get app_posts_trash_path
    assert_response :success
    assert_match @post.display_title, response.body
  end

  test "should show empty trash message" do
    get app_posts_trash_path
    assert_response :success
    assert_match "Your trash is empty", response.body
  end

  test "should discard post via create" do
    assert_no_difference("@user.blog.posts.count") do
      post app_posts_trash_path, params: { post_token: @post.token }
    end
    assert @post.reload.discarded?
    assert_redirected_to app_posts_path
  end

  test "should not discard post belonging to another user" do
    other_post = blogs(:elliot).posts.create!(title: "Other post", content: "Content")

    post app_posts_trash_path, params: { post_token: other_post.token }
    assert_response :not_found
  end

  test "should empty trash" do
    @post.discard!
    other = @user.blog.posts.create!(title: "Another", content: "Content")
    other.discard!

    assert_difference("@user.blog.posts.count", -2) do
      delete app_posts_trash_path
    end

    assert_redirected_to app_posts_trash_path
    assert_equal "Trash was successfully emptied", flash[:notice]
  end

  test "empty trash only removes current user's discarded posts" do
    @post.discard!
    other_post = blogs(:elliot).posts.create!(title: "Other post", content: "Content")
    other_post.discard!

    delete app_posts_trash_path

    assert_raises(ActiveRecord::RecordNotFound) { @post.reload }
    assert other_post.reload.discarded?
  end
end
