require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:joel)
  end

  test "an undeliverable address does not raise, so the delivery job is not retried" do
    raising_delivery CloudflareEmail::UndeliverableError

    assert_nothing_raised do
      AccountVerificationMailer.with(user: @user).login.deliver_now
    end
  end

  test "an undeliverable login email is reported to Sentry without retrying" do
    raising_delivery CloudflareEmail::UndeliverableError
    Sentry.expects(:capture_exception)

    assert_nothing_raised do
      AccountVerificationMailer.with(user: @user).login.deliver_now
    end
  end

  test "other delivery errors still raise, so the delivery job retries" do
    raising_delivery CloudflareEmail::DeliveryError

    assert_raises CloudflareEmail::DeliveryError do
      AccountVerificationMailer.with(user: @user).login.deliver_now
    end
  end

  test "an inactive Postmark recipient does not raise, so the delivery job is not retried" do
    raising_delivery Postmark::InactiveRecipientError

    assert_nothing_raised do
      EmailSubscriptionConfirmationMailer.with(subscriber: email_subscribers(:two)).confirm.deliver_now
    end
  end

  private

    def raising_delivery(error)
      Mail::TestMailer.any_instance.stubs(:deliver!).raises(error, "Cloudflare error")
    end
end
