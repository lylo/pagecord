require "test_helper"

class App::Posts::OpenGraphImagesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @post = posts(:one)
    @user.blog.update!(features: [ "open_graph_image" ])
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
end
