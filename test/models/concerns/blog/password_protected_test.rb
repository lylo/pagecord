require "test_helper"

class Blog::PasswordProtectedTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "password_protected? reflects presence of a password" do
    assert_not @blog.password_protected?

    @blog.update!(password: "letmein")

    assert @blog.password_protected?
    assert @blog.authenticate("letmein")
    assert_not @blog.authenticate("wrong")
  end

  test "blank password on update does not clear an existing password" do
    @blog.update!(password: "letmein")

    @blog.update!(title: "New Title", password: "")

    assert @blog.reload.password_protected?
    assert @blog.authenticate("letmein")
  end

  test "unticking the box clears the digest from the database" do
    @blog.update!(password: "letmein")

    @blog.update!(use_password: false)

    assert_nil @blog.reload.password_digest
    assert_not @blog.password_protected?
  end

  test "ticking the box without a password is rejected" do
    @blog.use_password = true

    assert_not @blog.valid?
    assert_equal "Password can't be blank", @blog.errors.full_messages_for(:password).first
  end

  # The upper bound is bcrypt's: it silently truncates past 72, which would
  # quietly make two different long passwords interchangeable.
  test "a password has to be a sensible length" do
    range = Blog::PasswordProtected::PASSWORD_RANGE

    @blog.password = "a" * (range.min - 1)
    assert_not @blog.valid?

    @blog.password = "a" * (range.max + 1)
    assert_not @blog.valid?

    @blog.password = "a" * range.min
    assert @blog.valid?
  end

  # Blog settings share one update endpoint, so a form that omits the box
  # entirely must not be read as a request to unprotect the blog.
  test "a form that omits the box leaves the password alone" do
    @blog.update!(password: "letmein")

    @blog.update!(title: "New Title")

    assert @blog.reload.password_protected?
  end

  test "an unprotected blog has no feed token" do
    assert_nil @blog.feed_token
    assert_not @blog.valid_feed_token?("")
    assert_not @blog.valid_feed_token?(nil)
  end

  test "the feed token cycles with the password" do
    @blog.update!(password: "letmein")
    was = @blog.feed_token

    assert_predicate was, :present?
    assert @blog.valid_feed_token?(was)
    assert_not @blog.valid_feed_token?("nope")

    @blog.update!(password: "different")

    assert_not_equal was, @blog.feed_token
    assert_not @blog.valid_feed_token?(was)
  end

  test "the feed token dies when protection is removed" do
    @blog.update!(password: "letmein")
    was = @blog.feed_token

    @blog.update!(use_password: false)

    assert_nil @blog.feed_token
    assert_not @blog.valid_feed_token?(was)
  end
end
