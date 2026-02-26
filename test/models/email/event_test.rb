require "test_helper"

class Email::EventTest < ActiveSupport::TestCase
  setup do
    @delivery = post_digest_deliveries(:one)
  end

  test "belongs to post_digest_delivery" do
    event = Email::Event.create!(
      message_id: "ses-abc123",
      provider: "ses",
      post_digest_delivery: @delivery
    )
    assert_equal @delivery, event.post_digest_delivery
  end

  test "validates provider inclusion" do
    event = Email::Event.new(
      message_id: "ses-abc123",
      provider: "invalid",
      post_digest_delivery: @delivery
    )
    refute event.valid?
    assert event.errors[:provider].present?
  end

  test "validates status inclusion" do
    event = Email::Event.new(
      message_id: "ses-abc123",
      provider: "ses",
      post_digest_delivery: @delivery,
      status: "invalid"
    )
    refute event.valid?
    assert event.errors[:status].present?
  end

  test "validates message_id presence" do
    event = Email::Event.new(
      message_id: nil,
      provider: "ses",
      post_digest_delivery: @delivery
    )
    refute event.valid?
    assert event.errors[:message_id].present?
  end

  test "default status is sent" do
    event = Email::Event.create!(
      message_id: "ses-def456",
      provider: "ses",
      post_digest_delivery: @delivery
    )
    assert_equal "sent", event.status
  end
end
