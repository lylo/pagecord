require "test_helper"

class App::Posts::OpenGraphImagesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @post = posts(:one)
    login_as @user
  end

  test "should destroy open graph image and redirect with notice" do
    @post.open_graph_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    assert @post.open_graph_image.attached?

    delete app_post_open_graph_image_path(@post)

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Open Graph image removed", flash[:notice]
    assert_not @post.reload.open_graph_image.attached?
  end

  test "should not destroy open graph image belonging to another user" do
    other_post = posts(:three)
    other_post.open_graph_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    delete app_post_open_graph_image_path(other_post)

    assert_response :not_found
    assert other_post.reload.open_graph_image.attached?
  end

  test "should destroy open graph image on a page and redirect to page edit" do
    page = posts(:about)
    page.open_graph_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    delete app_post_open_graph_image_path(page)

    assert_redirected_to edit_app_page_path(page)
    assert_equal "Open Graph image removed", flash[:notice]
    assert_not page.reload.open_graph_image.attached?
  end

  test "should destroy open graph image on home page and redirect to home page edit" do
    annie = users(:annie)
    login_as annie
    home_page = posts(:annie_home_page)
    home_page.open_graph_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    delete app_post_open_graph_image_path(home_page)

    assert_redirected_to edit_app_home_page_path
    assert_equal "Open Graph image removed", flash[:notice]
    assert_not home_page.reload.open_graph_image.attached?
  end
end
