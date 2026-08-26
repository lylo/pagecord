require "test_helper"

class ContentModerationTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
    @moderation = @post.create_content_moderation!(
      status: :flagged,
      flags: { "sexual" => true, "violence" => false, "hate" => true }
    )
  end

  test "flagged_categories returns only flagged ones" do
    assert_equal [ "hate", "sexual" ], @moderation.flagged_categories.sort
  end

  test "flagged_categories returns empty array when no flags" do
    @moderation.update!(flags: { "sexual" => false, "violence" => false })
    assert_equal [], @moderation.flagged_categories
  end

  test "has_flagged_content? returns true when any flag is true" do
    assert @moderation.has_flagged_content?
  end

  test "has_flagged_content? returns false when all flags are false" do
    @moderation.update!(flags: { "sexual" => false, "violence" => false })
    refute @moderation.has_flagged_content?
  end

  test "needs_review scope includes pending and error" do
    @moderation.update!(status: :pending)
    assert_includes ContentModeration.needs_review, @moderation

    @moderation.update!(status: :error)
    assert_includes ContentModeration.needs_review, @moderation

    @moderation.update!(status: :clean)
    refute_includes ContentModeration.needs_review, @moderation

    @moderation.update!(status: :flagged)
    refute_includes ContentModeration.needs_review, @moderation
  end
end
