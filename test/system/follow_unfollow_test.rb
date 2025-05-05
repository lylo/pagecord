require "application_system_test_case"

class FollowsTest < ApplicationSystemTestCase
  setup do
    @joel = users(:joel)
    @vivian = users(:vivian)
    @perform_jobs = ActiveJob::Base.queue_adapter.perform_enqueued_jobs
  end

  teardown do
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = @perform_jobs
  end

  test "user can follow and unfollow a blog" do
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true

    visit login_path

    fill_in "user[username]", with: @vivian.blog.name
    fill_in "user[email]", with: @vivian.email

    click_on "Login"

    assert_text "Thanks. We've sent you an email with your log in link."
    assert_not_nil @vivian.access_requests.last

    visit verify_access_request_url(token: @vivian.access_requests.last.token_digest)

    assert_current_path app_posts_path

    # Go to joel's blog
    visit blog_posts_path(name: @joel.blog.name)

    # Follow joel
    within("turbo-frame##{dom_id(@joel.blog)}-follow-button") do
      click_on "Follow"
    end

    # Check that the button now says "Unfollow"
    within("turbo-frame##{dom_id(@joel.blog)}-follow-button") do
      assert_text "Unfollow"
    end

    assert @vivian.following?(@joel.blog)

    # Unfollow joel
    within("turbo-frame##{dom_id(@joel.blog)}-follow-button") do
      click_on "Unfollow"
    end

    # Check that the button now says "Follow"
    within("turbo-frame##{dom_id(@joel.blog)}-follow-button") do
      assert_text "Follow"
    end

    assert_not @vivian.following?(@joel.blog)
  end
end
