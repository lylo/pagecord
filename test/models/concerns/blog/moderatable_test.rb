require "test_helper"

class Blog::ModeratableTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  def attach_avatar
    @blog.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
  end

  test "moderation_image_payloads is empty without an avatar" do
    assert_equal [], @blog.moderation_image_payloads
  end

  test "moderation_image_payloads builds a base64 image payload from the avatar" do
    attach_avatar

    payloads = @blog.moderation_image_payloads

    assert_equal 1, payloads.size
    assert_equal "image_url", payloads.first[:type]
    assert_match %r{\Adata:image/png;base64,}, payloads.first.dig(:image_url, :url)
  end

  test "moderation_text_payload is nil" do
    assert_nil @blog.moderation_text_payload
  end

  test "needs_avatar_moderation? is false without an avatar" do
    refute @blog.needs_avatar_moderation?
  end

  test "needs_avatar_moderation? is true when no moderation record exists" do
    attach_avatar
    assert @blog.needs_avatar_moderation?
  end

  test "needs_avatar_moderation? is false when fingerprint matches" do
    attach_avatar
    @blog.create_avatar_moderation!(status: :clean, fingerprint: @blog.avatar_moderation_fingerprint)

    refute @blog.needs_avatar_moderation?
  end

  test "needs_avatar_moderation? is true when fingerprint differs" do
    attach_avatar
    @blog.create_avatar_moderation!(status: :clean, fingerprint: "stale")

    assert @blog.needs_avatar_moderation?
  end
end
