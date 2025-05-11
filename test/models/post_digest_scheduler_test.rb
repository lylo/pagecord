require "test_helper"

class PostDigestSchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    @user.update!(timezone: "Pacific/Honolulu")  # Change timezone to Hawaii (UTC-10)
  end

  test "should queue digest at 8am in local user timezone" do
    # Simulate 8am in Hawaii (UTC-10)
    travel_to Time.utc(2025, 5, 11, 18, 0) do
      assert_enqueued_jobs 1 do
        PostDigestScheduler.run
      end
    end
  end

  test "should not queue digest if email subscriptions are disabled" do
    @user.blog.update!(email_subscriptions_enabled: false)

    # Simulate 8am in Hawaii (UTC-10)
    travel_to Time.utc(2025, 5, 11, 18, 0) do
      assert_enqueued_jobs 0 do
        PostDigestScheduler.run
      end
    end
  end

  test "should not queue digest if user is discarded" do
    @user.discard!

    # Simulate 8am in Hawaii (UTC-10)
    travel_to Time.utc(2025, 5, 11, 18, 0) do
      assert_enqueued_jobs 0 do
        PostDigestScheduler.run
      end
    end
  end

  test "should not queue digest if user isn't subscribed" do
    @user.subscription.destroy!

    # Simulate 8am in Hawaii (UTC-10)
    travel_to Time.utc(2025, 5, 11, 18, 0) do
      assert_enqueued_jobs 0 do
        PostDigestScheduler.run
      end
    end
  end

  test "should not queue digest at 5am in local user timezone" do
    # Simulate 5am in Hawaii (UTC-10)
    travel_to Time.utc(2025, 5, 11, 15, 0) do
      assert_no_enqueued_jobs do
        PostDigestScheduler.run
      end
    end
  end
end
