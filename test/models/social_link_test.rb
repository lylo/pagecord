require "test_helper"

class SocialLinkTest < ActiveSupport::TestCase
  setup do
    @link = social_links(:joel_instagram)
  end

  test "platform is unique per blog" do
    duplicate_link = @link.dup

    assert_not duplicate_link.valid?
    assert_includes duplicate_link.errors.full_messages, "Platform has already been taken"
  end

  test "should be invalid with unknown platform" do
    @link.platform = "Unknown"

    assert_not @link.valid?
    assert_includes @link.errors.full_messages, "Platform is not included in the list"
  end
end
