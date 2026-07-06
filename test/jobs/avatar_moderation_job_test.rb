require "test_helper"
require "mocha/minitest"

class AvatarModerationJobTest < ActiveJob::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @blog = blogs(:joel)
    @blog.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  def stub_result(status:, flags:, scores:)
    result = ContentModerator::Result.new(status: status, flags: flags, scores: scores, model_version: "test")
    ContentModerator.any_instance.stubs(:moderate)
    ContentModerator.any_instance.stubs(:result).returns(result)
    ContentModerator.any_instance.stubs(:error?).returns(status == :error)
    ContentModerator.any_instance.stubs(:flagged?).returns(status == :flagged)
  end

  test "skips non-existent blogs" do
    ContentModerator.any_instance.expects(:moderate).never
    AvatarModerationJob.perform_now(999999)
  end

  test "skips blogs without an avatar" do
    @blog.avatar.purge
    ContentModerator.any_instance.expects(:moderate).never
    AvatarModerationJob.perform_now(@blog.id)
  end

  test "skips blogs whose avatar was already moderated" do
    @blog.create_avatar_moderation!(status: :clean, fingerprint: @blog.avatar_moderation_fingerprint)
    ContentModerator.any_instance.expects(:moderate).never
    AvatarModerationJob.perform_now(@blog.id)
  end

  test "moderates and stores a clean result" do
    stub_result(status: :clean, flags: { "sexual" => false }, scores: { "sexual" => 0.01 })

    AvatarModerationJob.perform_now(@blog.id)

    moderation = @blog.reload.avatar_moderation
    assert moderation.clean?
    assert_not_nil moderation.moderated_at
    assert_equal @blog.avatar_moderation_fingerprint, moderation.fingerprint
  end

  test "moderates and stores a flagged result without removing the avatar" do
    stub_result(status: :flagged, flags: { "sexual" => true }, scores: { "sexual" => 0.9 })

    AvatarModerationJob.perform_now(@blog.id)

    moderation = @blog.reload.avatar_moderation
    assert moderation.flagged?
    assert @blog.avatar.attached?
    assert_includes AvatarModeration.needs_review, moderation
  end

  test "stores an error result" do
    stub_result(status: :error, flags: { error: "boom" }, scores: {})

    AvatarModerationJob.perform_now(@blog.id)

    assert @blog.reload.avatar_moderation.error?
  end
end
