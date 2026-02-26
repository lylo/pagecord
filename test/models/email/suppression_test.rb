require "test_helper"

class Email::SuppressionTest < ActiveSupport::TestCase
  test "suppressed? returns true for existing suppression" do
    assert Email::Suppression.suppressed?("bounced@example.com")
  end

  test "suppressed? returns false for unknown email" do
    refute Email::Suppression.suppressed?("clean@example.com")
  end

  test "suppressed? is case-insensitive and strips whitespace" do
    assert Email::Suppression.suppressed?("  BOUNCED@example.com  ")
  end

  test "suppress! creates a new suppression" do
    assert_difference "Email::Suppression.count", 1 do
      Email::Suppression.suppress!("new-bounce@example.com", reason: "bounce", bounce_type: "Permanent")
    end

    suppression = Email::Suppression.last
    assert_equal "new-bounce@example.com", suppression.email
    assert_equal "bounce", suppression.reason
    assert_equal "Permanent", suppression.bounce_type
    assert suppression.suppressed_at.present?
  end

  test "suppress! is idempotent for same email" do
    assert_no_difference "Email::Suppression.count" do
      Email::Suppression.suppress!("bounced@example.com", reason: "complaint")
    end
  end

  test "suppress! downcases email" do
    suppression = Email::Suppression.suppress!("UPPER@EXAMPLE.COM", reason: "bounce")
    assert_equal "upper@example.com", suppression.email
  end

  test "bounces scope returns only bounces" do
    bounces = Email::Suppression.bounces
    assert bounces.all? { |s| s.reason == "bounce" }
    assert bounces.exists?(email: "bounced@example.com")
    refute bounces.exists?(email: "complained@example.com")
  end

  test "complaints scope returns only complaints" do
    complaints = Email::Suppression.complaints
    assert complaints.all? { |s| s.reason == "complaint" }
    assert complaints.exists?(email: "complained@example.com")
    refute complaints.exists?(email: "bounced@example.com")
  end

  test "validates reason inclusion" do
    suppression = Email::Suppression.new(email: "test@example.com", reason: "invalid", suppressed_at: Time.current)
    refute suppression.valid?
    assert suppression.errors[:reason].present?
  end
end
