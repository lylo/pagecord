require "application_system_test_case"

class FollowsTest < ApplicationSystemTestCase
  setup do
    @user1 = users(:joel)
    @user2 = users(:vivian)
    @perform_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_jobs
  end

  teardown do
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = @perform_jobs
  end

  test "user can follow and unfollow another user" do
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true

    visit login_path

    fill_in "user[username]", with: @user1.username
    fill_in "user[email]", with: @user1.email

    click_on "Login"

    visit verify_access_request_url(token: @user1.access_requests.last.token_digest)

    # Go to user2's page
    visit user_posts_path(username: @user2.username)

    # Follow user2
    within("turbo-frame##{dom_id(@user2)}-follow-button") do
      click_on "Follow"
    end

    # Check that the button now says "Unfollow"
    within("turbo-frame##{dom_id(@user2)}-follow-button") do
      assert_text "Unfollow"
    end

    assert @user1.following?(@user2)

    # Unfollow user2
    within("turbo-frame##{dom_id(@user2)}-follow-button") do
      click_on "Unfollow"
    end

    # Check that the button now says "Follow"
    within("turbo-frame##{dom_id(@user2)}-follow-button") do
      assert_text "Follow"
    end

    assert_not @user1.following?(@user2)
  end
end