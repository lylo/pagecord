require "test_helper"

class CancellationMailerTest < ActionMailer::TestCase
  test "subscriber_cancellation says when Premium and the custom domain stop" do
    user = users(:annie)
    user.subscription.update!(next_billed_at: Time.zone.parse("2027-03-12"))
    email = CancellationMailer.with(user: user).subscriber_cancellation

    [ email.html_part, email.text_part ].each do |part|
      body = part.body.to_s
      assert_match "12 March 2027", body
      assert_match "annie.blog", body
      assert_match "11 April 2027", body
    end
  end
end
