require "test_helper"

class SendTrialEndedEmailsJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email to users whose trial ended yesterday" do
    user = User.create!(email: "trialended@example.com", trial_ends_at: Date.yesterday)

    assert_enqueued_email_with FreeTrialMailer, :trial_ended, params: { user: user } do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users still on trial" do
    User.create!(email: "stillontrial@example.com", trial_ends_at: 5.days.from_now.to_date)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users with active subscription" do
    user = users(:joel) # has subscription
    user.update!(trial_ends_at: Date.yesterday)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users whose trial ended more than a day ago" do
    User.create!(email: "oldtrial@example.com", trial_ends_at: 5.days.ago.to_date)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to discarded users" do
    user = User.create!(email: "discarded@example.com", trial_ends_at: Date.yesterday)
    user.discard!

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end

  test "does not send email to users without trial_ends_at (legacy users)" do
    user = User.create!(email: "legacy@example.com")
    user.update_column(:trial_ends_at, nil)

    assert_no_enqueued_emails do
      SendTrialEndedEmailsJob.perform_now
    end
  end
end
