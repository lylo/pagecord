require "test_helper"

class App::HomePagesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user

    @blog = @user.blog
    @blog.update!(features: [ "home_page" ])
  end

  # New action

  test "should get new" do
    get new_app_home_page_url
    assert_response :success
  end

  # Create action

  test "should create home page with title" do
    assert_difference("@blog.pages.count") do
      post app_home_page_url, params: { post: { title: "Welcome", content: "Welcome to my blog" } }
    end

    assert_redirected_to edit_app_home_page_path
    home_page = @blog.reload.home_page
    assert_equal "Welcome", home_page.title
    assert_equal true, home_page.is_page
    assert_equal false, home_page.show_in_navigation
    assert_equal "published", home_page.status
  end

  test "should create home page without title" do
    assert_difference("@blog.pages.count") do
      post app_home_page_url, params: { post: { content: "Welcome to my blog" } }
    end

    assert_redirected_to edit_app_home_page_path
    home_page = @blog.reload.home_page
    assert_nil home_page.title
    assert home_page.persisted?
  end

  test "should not create home page without content" do
    assert_no_difference("@blog.pages.count") do
      post app_home_page_url, params: { post: { title: "Welcome" } }
    end

    assert_response :unprocessable_entity
  end

  # Edit action

  test "should get edit when home page exists" do
    page = @blog.pages.build(content: "Home page content", status: :published)
    page.is_home_page = true
    page.save!
    @blog.update!(home_page_id: page.id)

    get edit_app_home_page_url
    assert_response :success
  end

  test "should redirect to new when home page does not exist" do
    get edit_app_home_page_url
    assert_redirected_to new_app_home_page_path
  end

  # Update action

  test "should update home page" do
    page = @blog.pages.create!(title: "Old Title", content: "Old content", status: :published)
    @blog.update!(home_page_id: page.id)

    patch app_home_page_url, params: { post: { title: "New Title", content: "New content" } }

    assert_redirected_to app_pages_path
    assert_equal "New Title", page.reload.title
    assert_equal "New content", page.content.to_plain_text.strip
  end

  test "should not update home page with invalid data" do
    page = @blog.pages.build(content: "Home page content", status: :published)
    page.is_home_page = true
    page.save!
    @blog.update!(home_page_id: page.id)

    patch app_home_page_url, params: { post: { content: "" } }

    assert_response :unprocessable_entity
  end

  # Destroy action

  test "should remove home page" do
    page = @blog.pages.create!(title: "Welcome", content: "Welcome content", status: :published)
    @blog.update!(home_page_id: page.id)

    delete app_home_page_url

    assert_redirected_to app_pages_path
    assert_nil @blog.reload.home_page_id
    assert page.reload.persisted?, "Page should still exist"
  end

  test "should set title on home page without title when removing" do
    page = @blog.pages.build(content: "Welcome content", status: :published)
    page.is_home_page = true
    page.save!
    @blog.update!(home_page_id: page.id)

    delete app_home_page_url

    assert_nil @blog.reload.home_page_id
    assert_equal "Home Page", page.reload.title
  end

  test "should not change title on home page with title when removing" do
    page = @blog.pages.create!(title: "My Homepage", content: "Welcome content", status: :published)
    @blog.update!(home_page_id: page.id)

    delete app_home_page_url

    assert_nil @blog.reload.home_page_id
    assert_equal "My Homepage", page.reload.title
  end
end
