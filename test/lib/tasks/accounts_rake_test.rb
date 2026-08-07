require "test_helper"
require "rake"

class AccountsRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("accounts:purge_cancellations")
    Rake::Task["accounts:purge_cancellations"].reenable

    @user = users(:vivian)
    @user.discard!
    @user.update!(discarded_at: 10.days.ago)
  end

  test "records the departure before purging the account" do
    assert_difference -> { Churn.count } do
      Rake::Task["accounts:purge_cancellations"].invoke
    end

    assert_not User.exists?(@user.id)

    churn = Churn.last
    assert_equal "account_deleted", churn.kind
    assert_equal @user.id, churn.user_id
    assert_in_delta 10.days.ago, churn.occurred_at, 1.second
  end

  test "leaves accounts still inside the grace period alone" do
    @user.update!(discarded_at: 1.day.ago)

    assert_no_difference -> { Churn.count } do
      Rake::Task["accounts:purge_cancellations"].invoke
    end

    assert User.exists?(@user.id)
  end
end
