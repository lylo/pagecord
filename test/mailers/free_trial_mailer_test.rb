require "test_helper"

class FreeTrialMailerTest < ActionMailer::TestCase
  test "trial_ended email is sent to user" do
    user = users(:vivian) # no subscription
    email = FreeTrialMailer.with(user: user).trial_ended

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "vivian@pagecord.com" ], email.to
    assert_equal "Your Pagecord free trial has ended", email.subject
  end

  test "trial_ended email links to the subscription page without quoting a price" do
    email = FreeTrialMailer.with(user: users(:vivian)).trial_ended

    [ email.html_part, email.text_part ].each do |part|
      assert_match %r{/app/settings/subscriptions}, part.body.to_s
      assert_no_match(/\$\d/, part.body.to_s)
    end
  end

  test "trial_reminder email names the day the trial ends" do
    user = users(:vivian)
    user.update!(trial_ends_at: Date.new(2026, 10, 8))
    email = FreeTrialMailer.with(user: user).trial_reminder

    assert_equal "Your Pagecord free trial ends on Thursday 8 October", email.subject
    assert_match "Thursday 8 October", email.text_part.body.to_s
  end
end
