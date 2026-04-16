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

  test "should sort pages by recently updated when requested" do
    @page.update_columns(title: "Archive Page", updated_at: 2.days.ago)
    posts(:contact).update_columns(title: "Fresh Notes", updated_at: 1.hour.ago)

    get app_pages_path(sort: "updated")

    assert_response :success
    assert_operator response.body.index("Fresh Notes"), :<, response.body.index("Archive Page")
  end

  test "should sort pages by remembered cookie preference" do
    @page.update_columns(title: "Archive Page", updated_at: 2.days.ago)
    posts(:contact).update_columns(title: "Fresh Notes", updated_at: 1.hour.ago)

    get app_pages_path(sort: "updated")
    get app_pages_path

    assert_response :success
    assert_operator response.body.index("Fresh Notes"), :<, response.body.index("Archive Page")
  end

  test "should get new" do
    get new_app_page_path
    assert_response :success
  end

  test "should create page" do
    assert_difference("@blog.pages.count") do
      post app_pages_path, params: {
        context_blog_id: @blog.id,
        post: {
          title: "New Page",
          content: "Page content"
        }
      }
    end

    page = @blog.pages.last
    assert page.page?
    assert_redirected_to app_pages_path
  end

  test "should create draft page" do
    assert_difference("@blog.pages.count") do
      post app_pages_path, params: {
        context_blog_id: @blog.id,
        post: {
          title: "Test Draft Page",
          content: "Draft content"
        },
        button: "save_draft"
      }
    end

    page = @blog.pages.last
    assert page.page?
    assert page.draft?
  end

  test "should get edit" do
    get edit_app_page_path(@page)
    assert_response :success
  end

  test "should not create page when form blog context does not match session blog" do
    assert_no_difference("@blog.pages.count") do
      post app_pages_path, params: {
        context_blog_id: users(:elliot).blog.id,
        post: {
          title: "New Page",
          content: "Page content"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Your browser session changed while you were editing."
    assert_includes response.body, "New Page"
  end

  test "should update page" do
    patch app_page_path(@page), params: {
      post: {
        title: "Updated About",
        content: "Updated content"
      }
    }

    @page.reload
    assert_equal "Updated About", @page.title
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

  test "should discard page" do
    page_to_discard = @blog.pages.first
    assert_no_difference("@blog.pages.count") do
      delete app_page_path(page_to_discard)
    end
    assert page_to_discard.reload.discarded?
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
        context_blog_id: @blog.id,
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
        context_blog_id: @blog.id,
        post: {
          title: "Title without content"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should set page as home page" do
    assert_nil @blog.home_page_id

    post set_as_home_page_app_page_path(@page)

    @blog.reload
    assert_equal @page.id, @blog.home_page_id
    assert_redirected_to app_pages_path
    assert_equal "Home page set!", flash[:notice]
  end

  test "should not set other user's page as home page" do
    other_blog = blogs(:elliot)
    other_page = other_blog.posts.create!(
      title: "Other Page",
      content: "Other content",
      is_page: true,
      status: :published
    )

    post set_as_home_page_app_page_path(other_page.token)

    assert_response :not_found
    @blog.reload
    assert_nil @blog.home_page_id
  end

  test "should set draft page as home page" do
    assert_nil @blog.home_page_id

    post set_as_home_page_app_page_path(@draft_page)

    @blog.reload
    assert_equal @draft_page.id, @blog.home_page_id
    assert_redirected_to app_pages_path
    assert_equal "Home page set!", flash[:notice]
  end

  test "should update page with open graph image" do
    @blog.update!(features: [ "open_graph_image" ])
    image = fixture_file_upload("avatar.png", "image/png")

    patch app_page_path(@page), params: { post: { open_graph_image: image } }

    assert_redirected_to app_pages_path
    assert @page.reload.open_graph_image.attached?
  end

  test "should update page with open_graph_image_suppressed" do
    @blog.update!(features: [ "open_graph_image" ])

    patch app_page_path(@page), params: { post: { open_graph_image_suppressed: true } }

    assert_redirected_to app_pages_path
    assert @page.reload.open_graph_image_suppressed?
  end

  test "should preview draft page with blog layout" do
    get app_post_path(@draft_page)

    assert_response :success
    assert_select "article"
    assert_select ".lexxy-content"
  end
end
