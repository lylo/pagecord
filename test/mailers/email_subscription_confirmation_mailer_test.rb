require "test_helper"

class EmailSubscriptionConfirmationMailerTest < ActionMailer::TestCase
  test "confirmation email renders correctly" do
    subscriber = email_subscribers(:two)

    email = EmailSubscriptionConfirmationMailer.with(subscriber: subscriber).confirm

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ subscriber.email ], email.to
    assert_equal "Confirm your subscription to #{subscriber.blog.display_name}", email.subject
    assert_match subscriber.token, email.body.encoded
  end

  test "confirmation email carries a List-Unsubscribe header Mailpace will deliver" do
    subscriber = email_subscribers(:two)

    email = EmailSubscriptionConfirmationMailer.with(subscriber: subscriber).confirm

    # Mailpace reads this field as list_unsubscribe. It sends no other header,
    # so the URL has to answer a GET rather than rely on one-click.
    assert_equal "<#{unsubscribe_url(subscriber)}>", email.header["list_unsubscribe"].to_s
    assert_nil email.header["List-Unsubscribe-Post"].presence
  end

  test "confirmation email omits the preheader when none is set" do
    subscriber = email_subscribers(:two)

    email = EmailSubscriptionConfirmationMailer.with(subscriber: subscriber).confirm

    assert_no_match "preheader", email.body.encoded
  end

  private

    def unsubscribe_url(subscriber)
      Rails.application.routes.url_helpers.email_subscriber_unsubscribe_url(
        subscriber.token, host: subscriber.blog.host
      )
    end
end
