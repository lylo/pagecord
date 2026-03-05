require "test_helper"

class App::Pages::TrashControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @page = posts(:about) # This is a page
  end

  test "should get trash index with discarded pages" do
    @page.discard!
    get app_pages_trash_index_path
    assert_response :success
    assert_match @page.display_title, response.body
  end

  test "should show empty trash message" do
    get app_pages_trash_index_path
    assert_response :success
    assert_match "Your trash is empty", response.body
  end

  test "should restore discarded page" do
    @page.discard!
    assert @page.discarded?

    delete app_pages_trash_path(@page)

    assert_redirected_to app_pages_trash_index_path
    assert_equal "Page was successfully restored", flash[:notice]
    assert_not @page.reload.discarded?
  end

  test "should not restore page belonging to another user" do
    other_blog = blogs(:elliot)
    other_page = other_blog.posts.create!(
      title: "Other Page",
      content: "Other content",
      is_page: true
    )
    other_page.discard!

    delete app_pages_trash_path(other_page)
    assert_response :not_found
  end
end
