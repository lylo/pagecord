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

  test "should touch all kept blogs when discarding user" do
    user = users(:joel)
    second_blog = blogs(:joel_notes)
    old_time = 2.days.ago
    user.blogs.update_all(updated_at: old_time)
    mock_api = mock("paddle_api")
    mock_api.expects(:cancel_subscription).with(user.subscription.paddle_subscription_id).returns(true)
    PaddleApi.stubs(:new).returns(mock_api)

    DestroyUserJob.perform_now(user.id)

    assert_operator user.blog.reload.updated_at, :>, old_time
    assert_operator second_blog.reload.updated_at, :>, old_time
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
        DestroyUserJob.perform_now(@user.id, reason: :spam)
      end
    end
  end

  test "records a tombstone naming why the account went" do
    assert_difference -> { AccountTombstone.count }, 1 do
      DestroyUserJob.perform_now(@user.id, reason: :spam)
    end

    assert AccountTombstone.last.spam?
  end

  test "distinguishes an admin removal from a self-serve deletion" do
    DestroyUserJob.perform_now(@user.id, reason: :admin_deleted)

    assert AccountTombstone.last.admin_deleted?
  end

  test "treats a deletion with no options as the user's own" do
    DestroyUserJob.perform_now(@user.id)

    assert AccountTombstone.last.user_deleted?
  end

  test "a retry cannot write a second tombstone" do
    DestroyUserJob.perform_now(@user.id, reason: :spam)

    assert_no_difference -> { AccountTombstone.count } do
      assert_raises(Discard::RecordNotDiscarded) do
        DestroyUserJob.perform_now(@user.id, reason: :spam)
      end
    end
  end

  test "a spam tombstone records every subdomain the user had" do
    user = users(:joel)
    mock_api = mock("paddle_api")
    mock_api.stubs(:cancel_subscription).returns(true)
    PaddleApi.stubs(:new).returns(mock_api)

    DestroyUserJob.perform_now(user.id, reason: :spam)

    assert_equal user.blogs.pluck(:subdomain).join(" "), AccountTombstone.last.subdomain
  end
end
