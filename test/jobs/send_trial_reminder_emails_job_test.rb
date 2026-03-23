require "test_helper"

class SendTrialReminderEmailsJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends email to users whose trial ends in 3 days" do
    user = User.create!(email: "trialreminder@example.com", trial_ends_at: 3.days.from_now.to_date, verified: true)

    assert_enqueued_email_with FreeTrialMailer, :trial_reminder, params: { user: user } do
      SendTrialReminderEmailsJob.perform_now
    end
  end

  test "does not send email to users still on trial with more than 3 days left" do
    User.create!(email: "stillontrial@example.com", trial_ends_at: 10.days.from_now.to_date, verified: true)

    assert_no_enqueued_emails do
      SendTrialReminderEmailsJob.perform_now
    end
  end

  test "does not send email to users with active subscription" do
    user = users(:joel) # has subscription
    user.update!(trial_ends_at: 3.days.from_now.to_date)

    assert_no_enqueued_emails do
      SendTrialReminderEmailsJob.perform_now
    end
  end

  test "does not send email to users whose trial already ended" do
    User.create!(email: "expired@example.com", trial_ends_at: Date.yesterday, verified: true)

    assert_no_enqueued_emails do
      SendTrialReminderEmailsJob.perform_now
    end
  end

  test "does not send email to discarded users" do
    user = User.create!(email: "discarded@example.com", trial_ends_at: 3.days.from_now.to_date, verified: true)
    user.discard!

    assert_no_enqueued_emails do
      SendTrialReminderEmailsJob.perform_now
    end
  end

  test "does not send email to unverified users" do
    User.create!(email: "unverified@example.com", trial_ends_at: 3.days.from_now.to_date, verified: false)

    assert_no_enqueued_emails do
      SendTrialReminderEmailsJob.perform_now
    end
  end
end
