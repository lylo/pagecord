require "test_helper"

class SendTrialEndedEmailsJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email to users whose trial ended today" do
    user = User.create!(email: "trialended@example.com", created_at: Subscribable::TRIAL_PERIOD_DAYS.days.ago)

    assert_enqueued_email_with FreeTrialMailer, :trial_ended, params: { user: user } do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users still on trial" do
    User.create!(email: "stillontrial@example.com", created_at: 5.days.ago)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users with active subscription" do
    user = users(:joel) # has subscription
    user.update!(created_at: Subscribable::TRIAL_PERIOD_DAYS.days.ago)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users whose trial ended more than a day ago" do
    User.create!(email: "oldtrial@example.com", created_at: 20.days.ago)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to discarded users" do
    user = User.create!(email: "discarded@example.com", created_at: Subscribable::TRIAL_PERIOD_DAYS.days.ago)
    user.discard!

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end
end
