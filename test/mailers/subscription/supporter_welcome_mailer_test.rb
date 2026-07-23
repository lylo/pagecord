require "test_helper"

class Subscription::SupporterWelcomeMailerTest < ActionMailer::TestCase
  test "welcome email is sent to the subscriber" do
    subscription = subscriptions(:one)
    email = Subscription::SupporterWelcomeMailer.welcome(subscription)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ subscription.user.email ], email.to
    assert_equal "Thank you for becoming a Pagecord Supporter 💛", email.subject
  end

  test "welcome email renders both html and text parts" do
    subscription = subscriptions(:one)
    email = Subscription::SupporterWelcomeMailer.welcome(subscription)

    assert_match(/Pagecord Supporter/, email.html_part.body.to_s)
    assert_match(/Pagecord Supporter/, email.text_part.body.to_s)
    assert_match(/supporters page/, email.text_part.body.to_s)
  end
end
