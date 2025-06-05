require "test_helper"

class App::PagesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
    @blog = blogs(:joel)
    @page = posts(:about)  # This is now a Post with is_page: true
    @draft_page = posts(:draft_page)
  end

  test "should get index" do
    get app_pages_path
    assert_response :success
  end

  test "should get new" do
    get new_app_page_path
    assert_response :success
  end

  test "should create page" do
    assert_difference("@blog.pages.count") do
      post app_pages_path, params: {
        post: {
          title: "New Page",
          content: "Page content",
          show_in_navigation: true
        }
      }
    end

    page = @blog.pages.last
    assert page.page?
    assert page.show_in_navigation?
    assert_redirected_to app_pages_path
  end

  test "should create draft page" do
    assert_difference("@blog.pages.count") do
      post app_pages_path, params: {
        post: {
          title: "Test Draft Page",
          content: "Draft content",
          show_in_navigation: false
        },
        button: "save_draft"
      }
    end

    page = @blog.pages.last
    assert page.page?
    assert page.draft?
    assert_not page.show_in_navigation?
  end

  test "should get edit" do
    get edit_app_page_path(@page)
    assert_response :success
  end

  test "should update page" do
    patch app_page_path(@page), params: {
      post: {
        title: "Updated About",
        content: "Updated content",
        show_in_navigation: false
      }
    }

    @page.reload
    assert_equal "Updated About", @page.title
    assert_not @page.show_in_navigation?
    assert_redirected_to app_pages_path
  end

  test "should update page as draft" do
    patch app_page_path(@page), params: {
      post: {
        title: "Draft Update",
        content: "Draft content"
      },
      button: "save_draft"
    }

    @page.reload
    assert_equal "Draft Update", @page.title
    assert @page.draft?
  end

  test "should destroy page" do
    assert_difference("@blog.pages.count", -1) do
      delete app_page_path(@page)
    end

    assert_redirected_to app_pages_path
  end

  test "should not access other user's pages" do
    other_blog = blogs(:elliot)
    other_page = other_blog.posts.create!(
      title: "Other Page",
      content: "Other content",
      is_page: true
    )

    get app_page_path(other_page)
    assert_response :not_found
  end

  test "should not create page without title" do
    assert_no_difference("@blog.pages.count") do
      post app_pages_path, params: {
        post: {
          content: "Content without title"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create page without content" do
    assert_no_difference("@blog.pages.count") do
      post app_pages_path, params: {
        post: {
          title: "Title without content"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
