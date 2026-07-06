require "test_helper"

class Admin::Moderation::AvatarsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
    @blog = blogs(:vivian)
    @blog.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
    @moderation = @blog.create_avatar_moderation!(
      status: :flagged,
      flags: { "sexual" => true },
      moderated_at: Time.current
    )
  end

  test "index lists flagged avatars" do
    get admin_moderation_avatars_url

    assert_response :success
    assert_select "table"
    assert_includes @response.body, "@#{@blog.subdomain}"
  end

  test "dismiss keeps the avatar and marks it reviewed" do
    post dismiss_admin_moderation_avatar_url(@moderation)

    assert_redirected_to admin_moderation_avatars_path
    assert @blog.reload.avatar.attached?
    assert @moderation.reload.reviewed?
  end

  test "remove purges the avatar and marks it reviewed" do
    post remove_admin_moderation_avatar_url(@moderation)

    assert_redirected_to admin_moderation_avatars_path
    assert_not @blog.reload.avatar.attached?
    assert @moderation.reload.reviewed?
  end
end
