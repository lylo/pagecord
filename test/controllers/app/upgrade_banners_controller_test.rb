require "test_helper"

class App::UpgradeBannersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:vivian) # Post-trial, non-subscribed user (created 30 days ago)
    login_as @user
  end

  test "should dismiss banner and redirect" do
    delete app_upgrade_banner_path
    assert_redirected_to app_root_path
    assert cookies[:upgrade_banner_dismissed].present?
  end

  test "should dismiss banner via turbo stream" do
    delete app_upgrade_banner_path, as: :turbo_stream
    assert_response :success
    assert cookies[:upgrade_banner_dismissed].present?
  end

  test "upgrade banner is visible for post-trial non-subscribed user" do
    get app_posts_path
    assert_select "turbo-frame#upgrade_banner"
    assert_select "a", text: "Upgrade to premium"
  end

  test "upgrade banner is hidden when dismissed cookie is set" do
    cookies[:upgrade_banner_dismissed] = "true"
    get app_posts_path
    assert_select "turbo-frame#upgrade_banner", count: 0
  end

  test "trial banner is always visible and has no close button" do
    trial_user = users(:annie)
    trial_user.subscription.destroy
    trial_user.update!(trial_ends_at: 5.days.from_now) # Still on trial
    login_as trial_user

    get app_posts_path
    assert_select "turbo-frame#upgrade_banner", count: 0
    assert_match "left of your free Premium trial", response.body
  end

  test "trial banner is visible even when dismissed cookie is set" do
    trial_user = users(:annie)
    trial_user.subscription.destroy
    trial_user.update!(trial_ends_at: 5.days.from_now) # Still on trial
    login_as trial_user

    cookies[:upgrade_banner_dismissed] = "true"
    get app_posts_path
    assert_match "left of your free Premium trial", response.body
  end
end
