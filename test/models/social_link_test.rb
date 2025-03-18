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

  test "url must be present" do
    @link.url = nil
    assert_not @link.valid?
    assert_includes @link.errors.full_messages, "Url can't be blank"
  end

  test "url must be http or https" do
    @link.url = "javascript:alert(1)"
    assert_not @link.valid?
    assert_includes @link.errors.full_messages, "Url must be HTTP or HTTPS"
  end

  test "url must be valid" do
    @link.url = "not a url"
    assert_not @link.valid?
    assert_includes @link.errors.full_messages, "Url is not a valid URL"
  end

  test "accepts valid urls" do
    @link.url = "https://instagram.com/username"
    assert @link.valid?
  end

  test "mastodon scope" do
    assert_equal 1, blogs(:joel).social_links.mastodon.count
  end
end
