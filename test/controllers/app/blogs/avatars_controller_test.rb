require "test_helper"

class App::Blogs::AvatarsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should destroy avatar and redirect with notice" do
    @blog.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    assert @blog.avatar.attached?, "Avatar should be attached before test"

    delete app_blog_avatar_path(@blog)

    assert_redirected_to app_settings_appearance_index_path
    assert_equal "Avatar removed", flash[:notice]
    assert_not @blog.reload.avatar.attached?, "Avatar should be removed after destroy"
  end
end
