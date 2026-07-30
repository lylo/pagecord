require "test_helper"

class MailpaceMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:joel)
  end

  # A blocked address is permanent, so raising would have Sidekiq retry it 25
  # times over three weeks, each retry reporting to Sentry.
  test "a blocked address does not raise, so the delivery job is not retried" do
    raising_delivery 'MAILPACE Error: {"to" => ["contains a blocked address"]}'

    assert_nothing_raised do
      AccountVerificationMailer.with(user: @user).login.deliver_now
    end
  end

  test "other delivery errors still raise, so the delivery job retries" do
    raising_delivery "MAILPACE Error: 500 Internal Server Error"

    assert_raises Mailpace::DeliveryError do
      AccountVerificationMailer.with(user: @user).login.deliver_now
    end
  end

  private

    def raising_delivery(message)
      Mail::TestMailer.any_instance.stubs(:deliver!).raises(Mailpace::DeliveryError, message)
    end
end
