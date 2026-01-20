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

  test "trial_ended email contains upgrade pricing" do
    user = users(:vivian)
    email = FreeTrialMailer.with(user: user).trial_ended

    assert_match(/\$#{Subscription.price}\/year/, email.html_part.body.to_s)
    assert_match(/\$#{Subscription.price}\/year/, email.text_part.body.to_s)
  end

  test "trial_ended email contains blog URL" do
    user = users(:vivian)
    email = FreeTrialMailer.with(user: user).trial_ended

    assert_match(user.blog.subdomain, email.html_part.body.to_s)
    assert_match(user.blog.subdomain, email.text_part.body.to_s)
  end
end
