require "test_helper"
require "mocha/minitest"

class ContentModerationJobTest < ActiveJob::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @post = posts(:one)
    @post.update!(text_summary: "Test content")
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  test "skips non-existent posts" do
    ContentModerator.any_instance.expects(:moderate).never
    ContentModerationJob.perform_now(999999)
  end

  test "skips draft posts" do
    @post.update!(status: :draft)
    ContentModerator.any_instance.expects(:moderate).never
    ContentModerationJob.perform_now(@post.id)
  end

  test "moderates hidden posts" do
    @post.update!(hidden: true)
    result = ContentModerator::Result.new(
      status: :clean,
      flags: { "sexual" => false },
      scores: { "sexual" => 0.01 },
      model_version: "test"
    )
    ContentModerator.any_instance.stubs(:moderate)
    ContentModerator.any_instance.stubs(:result).returns(result)
    ContentModerator.any_instance.stubs(:flagged?).returns(false)

    ContentModerationJob.perform_now(@post.id)

    @post.reload
    assert_not_nil @post.content_moderation
  end

  test "skips discarded posts" do
    @post.discard!
    ContentModerator.any_instance.expects(:moderate).never
    ContentModerationJob.perform_now(@post.id)
  end

  test "moderates scheduled posts with future published_at" do
    @post.update!(published_at: 1.day.from_now)
    result = ContentModerator::Result.new(
      status: :clean,
      flags: { "sexual" => false },
      scores: { "sexual" => 0.01 },
      model_version: "test"
    )
    ContentModerator.any_instance.stubs(:moderate)
    ContentModerator.any_instance.stubs(:result).returns(result)
    ContentModerator.any_instance.stubs(:flagged?).returns(false)

    ContentModerationJob.perform_now(@post.id)

    @post.reload
    assert_not_nil @post.content_moderation
    assert @post.content_moderation.clean?
  end

  test "skips posts that dont need moderation" do
    fingerprint = @post.moderation_fingerprint
    @post.create_content_moderation!(status: :clean, fingerprint: fingerprint)
    ContentModerator.any_instance.expects(:moderate).never
    ContentModerationJob.perform_now(@post.id)
  end

  test "moderates post and creates clean content_moderation" do
    result = ContentModerator::Result.new(
      status: :clean,
      flags: { "sexual" => false },
      scores: { "sexual" => 0.01 },
      model_version: "test"
    )
    ContentModerator.any_instance.stubs(:moderate)
    ContentModerator.any_instance.stubs(:result).returns(result)
    ContentModerator.any_instance.stubs(:flagged?).returns(false)

    ContentModerationJob.perform_now(@post.id)

    @post.reload
    assert_not_nil @post.content_moderation
    assert @post.content_moderation.clean?
    assert_not_nil @post.content_moderation.moderated_at
    assert_not_nil @post.content_moderation.fingerprint
    assert_equal({ "sexual" => 0.01 }, @post.content_moderation.category_scores)
  end

  test "moderates post and creates flagged content_moderation without discarding" do
    result = ContentModerator::Result.new(
      status: :flagged,
      flags: { "sexual" => true },
      scores: { "sexual" => 0.85 },
      model_version: "test"
    )
    ContentModerator.any_instance.stubs(:moderate)
    ContentModerator.any_instance.stubs(:result).returns(result)
    ContentModerator.any_instance.stubs(:flagged?).returns(true)

    ContentModerationJob.perform_now(@post.id)

    @post.reload
    assert_not_nil @post.content_moderation
    assert @post.content_moderation.flagged?
    refute @post.discarded?
    assert_equal({ "sexual" => 0.85 }, @post.content_moderation.category_scores)
  end
end
