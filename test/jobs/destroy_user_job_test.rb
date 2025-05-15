require "test_helper"
require "mocha/minitest"

class DestroyUserJobTest < ActiveJob::TestCase
  def setup
    @user = users(:elliot)
  end

  test "should discard the user" do
    DestroyUserJob.perform_now(@user.id)

    assert @user.reload.discarded?
  end

  test "should not remove from marketing automation" do
    assert_no_difference("EmailSubscriber.count") do
      assert_no_enqueued_jobs(only: MarketingAutomation::DeleteContactJob) do
        DestroyUserJob.perform_now(@user.id)
      end
    end
  end

  test "should remove from marketing automation if spam flag is set" do
    # subscribe the user to the pagecord blog
    pagecord = blogs(:pagecord)
    pagecord.email_subscribers.create!(email: @user.email)

    assert_difference("EmailSubscriber.count", -1) do
      perform_enqueued_jobs do
        DestroyUserJob.perform_now(@user.id, spam: true)
      end
    end
  end
end
