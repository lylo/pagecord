require "test_helper"
require "mocha/minitest"

class Email::ProcessBouncesJobTest < ActiveJob::TestCase
  setup do
    @delivery = post_digest_deliveries(:one)
    @event = Email::Event.create!(
      message_id: "ses-test-msg-001",
      provider: "ses",
      post_digest_delivery: @delivery
    )

    @mock_sqs = mock("sqs_client")
    Aws::SQS::Client.stubs(:new).returns(@mock_sqs)

    stub_const(Email::ProcessBouncesJob, :QUEUE_URL, "https://sqs.eu-west-2.amazonaws.com/123/test-queue")
  end

  test "processes permanent bounce and creates suppression" do
    bounce_notification = build_sqs_message(
      notificationType: "Bounce",
      bounce: {
        bounceType: "Permanent",
        bouncedRecipients: [
          { emailAddress: "bounced-new@example.com", diagnosticCode: "smtp;550 User unknown" }
        ]
      },
      mail: { messageId: "ses-test-msg-001" }
    )

    expect_receive_then_empty(bounce_notification)
    @mock_sqs.expects(:delete_message).once

    assert_difference "Email::Suppression.count", 1 do
      Email::ProcessBouncesJob.perform_now
    end

    suppression = Email::Suppression.find_by(email: "bounced-new@example.com")
    assert_equal "bounce", suppression.reason
    assert_equal "Permanent", suppression.bounce_type
    assert_equal "smtp;550 User unknown", suppression.diagnostic_code
    assert_equal "bounced", @event.reload.status
  end

  test "processes complaint and creates suppression" do
    complaint_notification = build_sqs_message(
      notificationType: "Complaint",
      complaint: {
        complainedRecipients: [
          { emailAddress: "complainer@example.com" }
        ]
      },
      mail: { messageId: "ses-test-msg-001" }
    )

    expect_receive_then_empty(complaint_notification)
    @mock_sqs.expects(:delete_message).once

    assert_difference "Email::Suppression.count", 1 do
      Email::ProcessBouncesJob.perform_now
    end

    suppression = Email::Suppression.find_by(email: "complainer@example.com")
    assert_equal "complaint", suppression.reason
    assert_equal "complained", @event.reload.status
  end

  test "ignores transient bounces" do
    transient_notification = build_sqs_message(
      notificationType: "Bounce",
      bounce: {
        bounceType: "Transient",
        bouncedRecipients: [
          { emailAddress: "transient@example.com" }
        ]
      },
      mail: { messageId: "ses-test-msg-001" }
    )

    expect_receive_then_empty(transient_notification)
    @mock_sqs.expects(:delete_message).once

    assert_no_difference "Email::Suppression.count" do
      Email::ProcessBouncesJob.perform_now
    end
  end

  test "skips when queue URL is not configured" do
    stub_const(Email::ProcessBouncesJob, :QUEUE_URL, nil)
    # Should not call SQS at all
    Aws::SQS::Client.expects(:new).never
    Email::ProcessBouncesJob.perform_now
  end

  test "handles malformed JSON gracefully" do
    bad_message = OpenStruct.new(
      body: "not valid json",
      receipt_handle: "receipt-123"
    )

    response_with_messages = OpenStruct.new(messages: [ bad_message ])
    empty_response = OpenStruct.new(messages: [])

    @mock_sqs.expects(:receive_message).twice.returns(response_with_messages, empty_response)
    @mock_sqs.expects(:delete_message).once

    assert_nothing_raised do
      Email::ProcessBouncesJob.perform_now
    end
  end

  private

    def build_sqs_message(**notification)
      sns_body = { "Message" => notification.deep_stringify_keys.to_json }
      OpenStruct.new(
        body: sns_body.to_json,
        receipt_handle: "receipt-#{SecureRandom.hex(4)}"
      )
    end

    def expect_receive_then_empty(message)
      response_with_messages = OpenStruct.new(messages: [ message ])
      empty_response = OpenStruct.new(messages: [])
      @mock_sqs.expects(:receive_message).twice.returns(response_with_messages, empty_response)
    end

    def stub_const(klass, const_name, value)
      klass.send(:remove_const, const_name) if klass.const_defined?(const_name)
      klass.const_set(const_name, value)
    end
end
