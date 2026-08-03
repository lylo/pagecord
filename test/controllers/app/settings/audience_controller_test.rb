require "test_helper"

class App::Settings::AudienceControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "shows subscriber count when show_metrics is enabled" do
    get app_settings_audience_index_url

    assert_response :success
    assert_select "p", text: /Your blog has 1 email subscriber/
  end

  test "hides subscriber count when show_metrics is disabled" do
    @blog.update!(show_metrics: false)

    get app_settings_audience_index_url

    assert_response :success
    assert_select "p", text: /Your blog has/, count: 0
  end

  test "a lapsed subscriber can still download the subscriber list" do
    @user.subscription.update!(next_billed_at: 1.day.ago)

    get app_settings_audience_index_url

    assert_response :success
    assert_select "a[href=?]", app_settings_subscribers_path(format: :csv)
  end

  test "shows comments settings" do
    get app_settings_audience_index_url

    assert_response :success
    assert_select "input[name='blog[comments_enabled]']"
  end
end
