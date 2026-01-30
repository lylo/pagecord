require "test_helper"
require "mocha/minitest"

class Post::ModeratableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @post = posts(:one)
    @post.update!(text_summary: "Test content for moderation")
  end

  test "needs_moderation? returns true when no content_moderation exists" do
    assert_nil @post.content_moderation
    assert @post.needs_moderation?
  end

  test "needs_moderation? returns true for pending content_moderation" do
    @post.create_content_moderation!(status: :pending)
    assert @post.needs_moderation?
  end

  test "needs_moderation? returns true for error content_moderation" do
    @post.create_content_moderation!(status: :error)
    assert @post.needs_moderation?
  end

  test "needs_moderation? returns true when fingerprint is blank" do
    @post.create_content_moderation!(status: :clean, fingerprint: nil)
    assert @post.needs_moderation?
  end

  test "needs_moderation? returns true when fingerprint changed" do
    @post.create_content_moderation!(status: :clean, fingerprint: "old_fingerprint")
    assert @post.needs_moderation?
  end

  test "needs_moderation? returns false when fingerprint matches" do
    fingerprint = @post.moderation_fingerprint
    @post.create_content_moderation!(status: :clean, fingerprint: fingerprint)
    refute @post.needs_moderation?
  end

  test "moderation_text_payload combines title and text" do
    @post.update!(title: "Test Title", text_summary: "Test content")
    payload = @post.moderation_text_payload
    assert_includes payload, "Test Title"
  end

  test "moderation_text_payload returns nil when no title and no text content" do
    @post.stubs(:plain_text_content).returns("")
    @post.title = nil
    assert_nil @post.moderation_text_payload
  end

  test "moderation_flagged scope returns flagged posts" do
    @post.create_content_moderation!(status: :flagged)
    assert_includes Post.moderation_flagged, @post
  end

  test "moderation_flagged scope excludes clean posts" do
    @post.create_content_moderation!(status: :clean)
    refute_includes Post.moderation_flagged, @post
  end

  test "moderation_pending scope includes posts without content_moderation" do
    assert_nil @post.content_moderation
    assert_includes Post.moderation_pending, @post
  end

  test "moderation_pending scope includes posts with pending status" do
    @post.create_content_moderation!(status: :pending)
    assert_includes Post.moderation_pending, @post
  end

  test "moderation_pending scope includes posts with error status" do
    @post.create_content_moderation!(status: :error)
    assert_includes Post.moderation_pending, @post
  end

  test "moderation_pending scope excludes clean posts" do
    @post.create_content_moderation!(status: :clean, fingerprint: @post.moderation_fingerprint)
    refute_includes Post.moderation_pending, @post
  end

  test "fingerprint changes when title changes" do
    original_fingerprint = @post.moderation_fingerprint
    @post.title = "New Title"
    new_fingerprint = @post.moderation_fingerprint
    refute_equal original_fingerprint, new_fingerprint
  end

  test "fingerprint changes when plain_text_content changes" do
    original_fingerprint = @post.moderation_fingerprint
    @post.stubs(:plain_text_content).returns("Completely different content")
    new_fingerprint = @post.moderation_fingerprint
    refute_equal original_fingerprint, new_fingerprint
  end

  # Moderatable scope tests
  test "moderatable scope includes published posts" do
    @post.update!(status: :published, hidden: false)
    assert_includes Post.moderatable, @post
  end

  test "moderatable scope includes scheduled posts" do
    @post.update!(status: :published, hidden: false, published_at: 1.day.from_now)
    assert_includes Post.moderatable, @post
  end

  test "moderatable scope excludes draft posts" do
    @post.update!(status: :draft)
    refute_includes Post.moderatable, @post
  end

  test "moderatable scope includes hidden posts" do
    @post.update!(hidden: true)
    assert_includes Post.moderatable, @post
  end

  test "moderatable scope excludes discarded posts" do
    @post.discard!
    refute_includes Post.moderatable, @post
  end

end
