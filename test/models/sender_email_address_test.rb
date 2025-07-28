require "test_helper"

class SenderEmailAddressTest < ActiveSupport::TestCase
  test "should generate verification token on create" do
    sender = blogs(:joel).sender_email_addresses.create!(email: "sender@example.com")
    assert_not_nil sender.token_digest
    assert sender.token_digest.length > 20
  end

  test "should set verified to false on create" do
    sender = blogs(:joel).sender_email_addresses.create!(email: "sender@example.com")
    assert_not sender.accepted?
    assert_nil sender.accepted_at
  end

  test "should validate email presence" do
    sender = blogs(:joel).sender_email_addresses.new(email: "")
    assert_not sender.valid?
    assert_includes sender.errors[:email], "can't be blank"
  end

  test "should validate email format" do
    sender = blogs(:joel).sender_email_addresses.new(email: "invalid-email")
    assert_not sender.valid?
    assert_includes sender.errors[:email], "is invalid"
  end

  test "should allow valid email format" do
    sender = blogs(:joel).sender_email_addresses.new(email: "valid@example.com")
    assert sender.valid?
  end

  test "should validate email uniqueness within blog" do
    blog = blogs(:joel)
    blog.sender_email_addresses.create!(email: "duplicate@example.com")

    duplicate_sender = blog.sender_email_addresses.new(email: "duplicate@example.com")
    assert_not duplicate_sender.valid?
    assert_includes duplicate_sender.errors[:email], "has already been taken"
  end

  test "should allow same email for different blogs" do
    email = "shared@example.com"

    assert_difference("SenderEmailAddress.count", 2) do
      blogs(:joel).sender_email_addresses.create!(email: email)
      blogs(:vivian).sender_email_addresses.create!(email: email)
    end
  end

  test "should validate verification token uniqueness" do
    sender1 = blogs(:joel).sender_email_addresses.create!(email: "sender1@example.com")
    sender2 = blogs(:joel).sender_email_addresses.new(email: "sender2@example.com")
    sender2.token_digest = sender1.token_digest

    assert_not sender2.valid?
    assert_includes sender2.errors[:token_digest], "has already been taken"
  end

  test "should belong to blog" do
    sender = blogs(:joel).sender_email_addresses.create!(email: "sender@example.com")
    assert_equal blogs(:joel), sender.blog
  end

  test "should allow manual verification" do
    sender = blogs(:joel).sender_email_addresses.create!(email: "sender@example.com")

    assert_not sender.accepted?
    assert_nil sender.accepted_at
    assert_not_nil sender.token_digest

    sender.update!(accepted_at: Time.current, token_digest: nil)

    assert sender.accepted?
    assert_not_nil sender.accepted_at
    assert_nil sender.token_digest
  end

  test "should handle nil verification token gracefully" do
    sender = blogs(:joel).sender_email_addresses.new(email: "sender@example.com")
    sender.token_digest = nil
    sender.save!

    # Should generate token even if initially nil
    assert_not_nil sender.token_digest
  end

  test "should not override existing verification token" do
    sender = blogs(:joel).sender_email_addresses.new(email: "sender@example.com")
    custom_token = "custom-token-123"
    sender.token_digest = custom_token
    sender.save!

    assert_equal custom_token, sender.token_digest
  end
end
