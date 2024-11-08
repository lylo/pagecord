require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate length of username" do
    user = User.new(username: "a" * 21, email: "test@example.com")
    assert_not user.valid?

    user = User.new(username: "a", email: "test@example.com")
    assert_not user.valid?

    user = User.new(username: "aaaa", email: "test@example.com")
    assert user.valid?
  end

  test "should validate length of bio" do
    user = users(:joel)
    user.bio = "a" * 513
    assert_not user.valid?
  end

  test "should validate presence of username" do
    user = User.new(username: "", email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate uniqueness of username" do
    user = User.new(username: users(:joel).username, email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate format of username" do
    assert_not User.new(username: "abcdef-", email: "test@example.com").valid?
    assert_not User.new(username: "%12312", email: "test@example.com").valid?
    assert User.new(username: "abcdef_1234", email: "test@example.com").valid?
  end

  test "should validate format of email" do
    user = User.new(username: "newuser", email: "joel")
    assert_not user.valid?

    user = User.new(username: "newuser", email: "joel@blah.blahhhhh")
    assert user.valid?
  end

  test "should generate unique delivery email" do
    user = User.create!(username: "newuser", email: "newuser@newuser.com")
    assert user.delivery_email.present?
    assert user.delivery_email =~ /newuser_[a-zA-Z0-9]{8}@post.pagecord.com/
  end

  test "should store in lowercase" do
    user = User.create!(username: "NewUser", email: "nEwUser@NewUser.COM")
    assert_equal "newuser", user.username
    assert_equal "newuser@newuser.com", user.email
  end

  test "should strip whitespace" do
    user = User.create!(username: "newuser ", email: "newuser@newuser.com")
    assert_equal "newuser", user.username
    assert_equal "newuser@newuser.com", user.email
  end

  test "should allow valid custom domain" do
    user = User.new(username: "newuser", email: "newuser@newuser.com", custom_domain: "newuser.com")
    assert user.valid?
  end

  test "should not allow invalid custom domain format" do
    user = User.new(username: "newuser", email: "newuser@newuser.com", custom_domain: "blah blah")
    assert_not user.valid?
  end

  test "should validate restricted custom domain" do
    user = User.new(username: "newuser", email: "newuser@newuser.com", custom_domain: "pagecord.com")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Custom domain is restricted"
  end

  test "should record custom domain change" do
    user = users(:joel)
    user.update!(custom_domain: "newdomain.com")
    assert user.valid?
    assert_equal 1, user.custom_domain_changes.count
  end

  test "should be given a free trial on create" do
    user = User.create!(username: "newuser", email: "newuser@example.com")
    assert user.free_trial_ends_at.present?
    assert_not user.free_trial_expired?
    assert user.is_on_free_trial?
  end

  test "should expire free trial" do
    user = users(:vivian)
    user.update!(free_trial_ends_at: 1.day.ago)
    assert user.free_trial_expired?
  end
end
