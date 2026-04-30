require "test_helper"

class App::Pages::TrashControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @page = posts(:about) # This is a page
  end

  test "should get trash with discarded pages" do
    @page.discard!
    get app_pages_trash_path
    assert_response :success
    assert_match @page.display_title, response.body
  end

  test "should show empty trash message" do
    get app_pages_trash_path
    assert_response :success
    assert_match "Your trash is empty", response.body
  end

  test "should discard page via create" do
    assert_no_difference("@user.blog.pages.count") do
      post app_pages_trash_path, params: { page_token: @page.token }
    end
    assert @page.reload.discarded?
    assert_redirected_to app_pages_path
  end

  test "should clear home_page_id when discarding home page" do
    @user.blog.update!(home_page_id: @page.id)

    post app_pages_trash_path, params: { page_token: @page.token }

    assert_nil @user.blog.reload.home_page_id
    assert @page.reload.discarded?
  end

  test "should not discard page belonging to another user" do
    other_blog = blogs(:elliot)
    other_page = other_blog.posts.create!(
      title: "Other Page",
      content: "Other content",
      is_page: true
    )

    post app_pages_trash_path, params: { page_token: other_page.token }
    assert_response :not_found
  end

  test "should empty trash" do
    @page.discard!
    other = @user.blog.posts.create!(title: "Another", content: "Content", is_page: true)
    other.discard!

    assert_difference("@user.blog.pages.count", -2) do
      delete app_pages_trash_path
    end

    assert_redirected_to app_pages_trash_path
    assert_equal "Trash was successfully emptied", flash[:notice]
  end

  test "empty trash only removes current user's discarded pages" do
    @page.discard!
    other_blog = blogs(:elliot)
    other_page = other_blog.posts.create!(
      title: "Other Page",
      content: "Other content",
      is_page: true
    )
    other_page.discard!

    delete app_pages_trash_path

    assert_raises(ActiveRecord::RecordNotFound) { @page.reload }
    assert other_page.reload.discarded?
  end
end
