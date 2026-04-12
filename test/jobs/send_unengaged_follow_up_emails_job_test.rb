require "test_helper"

class SendUnengagedFollowUpEmailsJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "sends onboarding follow up to eligible account created user" do
    user = users(:saul)
    user.update!(created_at: 2.months.ago, verified: true)
    user.subscription.destroy!

    assert_enqueued_email_with WelcomeMailer, :onboarding_follow_up, params: { user: user } do
      SendUnengagedFollowUpEmailsJob.perform_now
    end

    assert user.reload.unengaged_follow_up.present?
  end

  test "sends no content follow up to eligible onboarded user with no content" do
    user = users(:unengaged)
    user.update!(created_at: 2.months.ago)

    assert_enqueued_email_with WelcomeMailer, :no_content_follow_up, params: { user: user } do
      SendUnengagedFollowUpEmailsJob.perform_now
    end

    assert user.reload.unengaged_follow_up.present?
  end

  test "skips account_created user who has posts" do
    user = users(:saul)
    user.update!(created_at: 2.months.ago, verified: true)
    user.subscription.destroy!
    user.blog.posts.create!(title: "Posted via email", content: "Hello", published_at: 1.week.ago)

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end

  test "skips users with posts" do
    user = users(:vivian) # has posts, no subscription
    user.update!(created_at: 2.months.ago)

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end

  test "skips users with pages" do
    user = users(:elliot) # has a page (non_nav_page), no subscription
    user.update!(onboarding_state: "completed", verified: true, created_at: 2.months.ago)

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end

  test "skips subscribed users" do
    user = users(:joel)
    user.update!(created_at: 2.months.ago)
    user.blog.all_posts.destroy_all

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end

  test "skips discarded users" do
    user = users(:unengaged)
    user.update!(created_at: 2.months.ago)
    user.discard!

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end

  test "skips users created less than 1 month ago" do
    users(:unengaged).update!(created_at: 2.weeks.ago)

    travel_to 2.weeks.from_now do
      assert_no_enqueued_emails do
        SendUnengagedFollowUpEmailsJob.perform_now
      end
    end
  end

  test "skips unverified users" do
    user = users(:unengaged)
    user.update!(created_at: 2.months.ago, verified: false)

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end

  test "skips already-sent users" do
    user = users(:unengaged)
    user.update!(created_at: 2.months.ago)
    user.create_unengaged_follow_up!(sent_at: 1.week.ago)

    assert_no_enqueued_emails do
      SendUnengagedFollowUpEmailsJob.perform_now
    end
  end
end
