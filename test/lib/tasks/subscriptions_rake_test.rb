require "test_helper"
require "rake"

class SubscriptionsRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("subscriptions:send_renewal_reminders")
    Rake::Task["subscriptions:send_renewal_reminders"].reenable
  end

  test "send_renewal_reminders runs the job" do
    subscription = subscriptions(:one)
    subscription.update!(next_billed_at: 13.days.from_now)

    assert_difference -> { Subscription::RenewalReminder.count } do
      Rake::Task["subscriptions:send_renewal_reminders"].invoke
    end
  end
end
